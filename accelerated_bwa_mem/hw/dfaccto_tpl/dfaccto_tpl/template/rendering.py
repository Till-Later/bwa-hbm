from .context import Context
from .errors import ParserError
from .renderbuffer import RenderBuffer



class Template:

  def __init__(self, content, name=None):
    self._content = content
    self._name = name or '<string>'

  def render_with(self, context, buf):
    for token in self._content:
      token.render_with(context, buf)

  def render(self, *context_items, no_indent=False, **context_kwargs):
    context = Context(*context_items, **context_kwargs)
    buf = RenderBuffer(no_indent=no_indent)
    self.render_with(context, buf)
    return buf.finish()

  def render_to(self, stream, *context_items, no_indent=False, **context_kwargs):
    context = Context(*context_items, **context_kwargs)
    buf = RenderBuffer(stream, no_indent=no_indent)
    self.render_with(context, buf)
    buf.finish()


class LiteralToken:
  def __init__(self, string):
    self._string = string

  @property
  def string(self):
    return self._string

  def set_string(self, string):
    self._string = string

  def render_with(self, context, buf):
    buf.write(self._string)


class ValueToken:
  # {{key}}
  # {{&key}}
  def __init__(self, key, verbatim=False):
    self._key = key
    self._verbatim = verbatim

  def render_with(self, context, buf):
    string = context.get_string(self._key, self._verbatim)
    buf.push_indent()
    buf.write(string)
    buf.pop_indent()


class IndirectToken:
  # {{*key}}
  def __init__(self, key, parser):
    self._key = key
    self._parser = parser

  def render_with(self, context, buf):
    template_string = context.get_string(self._key, True)
    template = self._parser.parse(template_string)
    buf.push_indent()
    template.render_with(context, buf)
    buf.pop_indent()


class PartialToken:
  # {{>name}}
  def __init__(self, name):
    self._name = name

  def render_with(self, context, buf):
    template = context.get_partial(self._name)
    if template is not None:
      buf.push_indent()
      template.render_with(context, buf)
      buf.remove_trailing()
      buf.pop_indent()


class SectionToken:
  # {{#key}}...[{{|key}}...]{{/key}} (mode=Loop)
  # {{=key}}...[{{|key}}...]{{/key}} (mode=Enter)
  # {{?key}}...[{{|key}}...]{{/key}} (mode=Check)
  # {{!key}}...[{{|key}}...]{{/key}} (mode=Exist)
  # {{^key}}...{{/key}}              (mode=Loop)
  def __init__(self, key, truthy_content, falsey_content, mode):
    """
      mode
        Loop: Render truthy content with items of iterable-coerced key-value, and if empty falsey content with original context
        Enter: Render truthy content with key-value directly if present, and if absent falsey content with original context
        Check: Render truthy content with original context if key-value is truthy, and if falsey or absent render falsey content with original context
        Exist: Render truthy content with original context if key-value is present, and if absent render falsey content with original context
    """
    self.key = key
    self.truthy_content = truthy_content
    self.falsey_content = falsey_content
    self.mode = mode
    if mode == 'Loop':
      self._get_iterable = True
      self._get_value = False
      self._get_exists = False
      self._do_push = True
    elif mode == 'Enter':
      self._get_iterable = False
      self._get_value = False
      self._get_exists = True
      self._do_push = True
    elif mode == 'Check':
      self._get_iterable = False
      self._get_value = True
      self._get_exists = False
      self._do_push = False
    elif mode == 'Exist':
      self._get_iterable = False
      self._get_value = False
      self._get_exists = True
      self._do_push = False
    else:
      raise ParserError('Invalid section mode "{}" must be Loop, Enter, Check or Exist'.format(mode))

  def _render_truthy(self, context, item, buf):
    if self.truthy_content:
      if self._do_push:
        context.push(item)
      for token in self.truthy_content:
        token.render_with(context, buf)
      if self._do_push:
        context.pop()

  def _render_falsey(self, context, buf):
    if self.falsey_content:
      for token in self.falsey_content:
        token.render_with(context, buf)

  def render_with(self, context, buf):
    if self._get_iterable:
      iterable = context.get_iterable(self.key)
      for item in iterable:
        self._render_truthy(context, item, buf)
      if not iterable:
        self._render_falsey(context, buf)
    elif self._get_value:
      value = context.get_value(self.key)
      if value:
        self._render_truthy(context, value, buf)
      else:
        self._render_falsey(context, buf)
    elif self._get_exists:
      if context.has_value(self.key):
        item = context.get_value(self.key)
        self._render_truthy(context, item, buf)
      else:
        self._render_falsey(context, buf)


