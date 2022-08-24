from .parser import Parser
from .rendering import Template, LiteralToken, ValueToken, IndirectToken, PartialToken, SectionToken
from .key import Key
from .context import Context
from .errors import TemplateError, ParserError, AbsentError



_default_parser = Parser()

def parse(template_str, name=None):
  return _default_parser.parse(template_str, name)


def render(template_str, *context_items, **kwargs):
  tpl = parse(template_str)
  return tpl.render(*context_items, **kwargs)


def render_to(template_str, stream, *context_items, **kwargs):
  tpl = parse(template_str)
  tpl.render_to(stream, *context_items, **kwargs)
