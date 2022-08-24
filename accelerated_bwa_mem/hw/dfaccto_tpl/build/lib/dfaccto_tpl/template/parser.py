import re
from collections import deque
from enum import Enum, auto

from .key import Key
from .errors import ParserError
from .rendering import Template, LiteralToken, ValueToken, IndirectToken, PartialToken, SectionToken



class SectionContainer:

  def __init__(self):
    self._content = list()
    self._last_literals = False

  def get(self):
    self._complete()
    return self._content

  def append_token(self, token):
    self._complete()
    self._content.append(token)

  def append_literal(self, literal):
    if self._last_literals:
      self._content[-1].append(literal)
    else:
      self._content.append([literal])
      self._last_literals = True

  def _complete(self):
    if self._last_literals:
      self._content[-1] = LiteralToken(''.join(self._content[-1]))
      self._last_literals = False

class SecKind(Enum):
  Root = auto()      # No section, but toplevel content
  Normal = auto()    # First part of normal section {{#...}} (push=True, loop=True)
  Enter = auto()     # First part of enter section {{=...}} (push=True, loop=False)
  Check = auto()     # First part of check section {{?...}} (push=False, loop=True)
  Exist = auto()    # First part of exists section {{!...}} (push=False, loop=False)
  Inverted = auto()  # Inverted section {{^...}}
  # Both = auto()      # Alternative part of non-inverted section after {{|...}}
  AltNormal = auto() # Alternative part of normal section after {{|...}}
  AltEnter = auto()  # Alternative part of enter section after {{|...}}
  AltCheck = auto()  # Alternative part of check section after {{|...}}
  AltExist = auto() # Alternative part of exists section after {{|...}}
  End = auto()       # No section, but end of section marker {{/...}}
  Alt = auto()       # No section, but alternative section marker {{|...}}

  @property
  def mode(self):
    Modes = {
      SecKind.Normal:    'Loop',
      SecKind.Enter:     'Enter',
      SecKind.Check:     'Check',
      SecKind.Exist:     'Exist',
      SecKind.Inverted:  'Loop',
      SecKind.AltNormal: 'Loop',
      SecKind.AltEnter:  'Enter',
      SecKind.AltCheck:  'Check',
      SecKind.AltExist:  'Exist'}
    return Modes.get(self)

  @property
  def loop_flag(self):
    return self in (SecKind.Normal, SecKind.Check, SecKind.AltNormal, SecKind.AltCheck)

  @property
  def can_alternate(self):
    return self in (SecKind.Normal, SecKind.Enter, SecKind.Check, SecKind.Exist)

  @property
  def alternate(self):
    Alternates = {
      SecKind.Normal: SecKind.AltNormal,
      SecKind.Enter:  SecKind.AltEnter,
      SecKind.Check:  SecKind.AltCheck,
      SecKind.Exist: SecKind.AltExist}
    return Alternates.get(self)

  @property
  def active_content(self):
    # True: truthy_content | False: falsey_content
    return self in (SecKind.Root, SecKind.Normal, SecKind.Enter, SecKind.Check, SecKind.Exist)

  def token_str(self, key):
    TokenFormats = {
      SecKind.Root:      '<root>',
      SecKind.Normal:    '{{{{#{0}}}}}',
      SecKind.Enter:     '{{{{={0}}}}}',
      SecKind.Check:     '{{{{?{0}}}}}',
      SecKind.Exist:    '{{{{!{0}}}}}',
      SecKind.Inverted:  '{{{{^{0}}}}}',
      SecKind.AltNormal: '{{{{#{0}}}}}{{{{|{0}}}}}',
      SecKind.AltEnter:  '{{{{={0}}}}}{{{{|{0}}}}}',
      SecKind.AltCheck:  '{{{{?{0}}}}}{{{{|{0}}}}}',
      SecKind.AltExist: '{{{{!{0}}}}}{{{{|{0}}}}}',
      SecKind.End:       '{{{{/{0}}}}}',
      SecKind.Alt:       '{{{{|{0}}}}}'}
    return TokenFormats[self].format(key)


class SectionStack:

  def __init__(self):
    self._stack = deque()
    # items: [kind, key, truthy_content, falsey_content]
    self.reset()

  def reset(self):
    self._stack.clear()
    self._stack.append([SecKind.Root, None, SectionContainer(), None, None])

  @property
  def top(self):
    return self._stack[-1]

  @property
  def kind(self):
    return self._stack[-1][0]

  @property
  def key(self):
    return self._stack[-1][1]

  @property
  def content(self):
    if self._stack[-1][0].active_content:
      return self._stack[-1][2]
    else:
      return self._stack[-1][3]

  @property
  def pos(self):
    return self._stack[-1][4]

  def token_str(self):
    token_str = self.kind.token_str(self.key)
    if self.pos is not None:
      return '{} at [{}:{}]'.format(token_str, *self.pos)
    else:
      return token_str

  def push_normal(self, key, pos):
    self._stack.append([SecKind.Normal, key, SectionContainer(), None, pos])

  def push_enter(self, key, pos):
    self._stack.append([SecKind.Enter, key, SectionContainer(), None, pos])

  def push_check(self, key, pos):
    self._stack.append([SecKind.Check, key, SectionContainer(), None, pos])

  def push_exists(self, key, pos):
    self._stack.append([SecKind.Exist, key, SectionContainer(), None, pos])

  def push_inverted(self, key, pos):
    self._stack.append([SecKind.Inverted, key, None, SectionContainer(), pos])

  def alternate(self, key, pos):
    if self.key != key:
      msg = 'Alternative token {} key mismatch with {}'
      raise ParserError(msg.format(SecKind.Alt.token_str(key),
                                   self.token_str()))
    if self.kind.can_alternate:
      self.top[0] = self.kind.alternate
      self.top[3] = SectionContainer()
      self.top[4] = pos
    elif self.kind is SecKind.Root:
      msg = 'Alternative token {} outside section'
      raise ParserError(msg.format(SecKind.Alt.token_str(key)))
    elif self.kind is SecKind.Inverted:
      msg = 'Alternative token {} can\'t be used with inverted sections'
      raise ParserError(msg.format(SecKind.Alt.token_str(key)))
    else:
      msg = 'Duplicate alternative token {}'
      raise ParserError(msg.format(SecKind.Alt.token_str(key)))

  def pop(self, key):
    if self.key != key:
      msg = 'Closing token {} key mismatch with {}'
      raise ParserError(msg.format(SecKind.End.token_str(key),
                                   self.token_str()))
    if self.kind is not SecKind.Root:
      kind, key, truthy, falsey, pos = self._stack.pop()
      return (key, truthy and truthy.get(), falsey and falsey.get(), kind.mode)
    else:
      msg = 'Closing token {} without open section'
      raise ParserError(msg.format(SecKind.End.token_str(key)))

  def take(self):
    if self.kind is SecKind.Root:
      kind, key, truthy, falsey, pos = self._stack.pop()
      return truthy.get()
    else:
      msg = 'Section token {} is never closed'
      raise ParserError(msg.format(self.token_str()))

  def append_token(self, token):
    self.content.append_token(token)

  def append_literal(self, literal):
    self.content.append_literal(literal)


class State(Enum):
  Begin = auto()
  Space = auto()
  Print = auto()
  BeginToken = auto()
  SpaceToken = auto()
  BeginTokenSpace = auto()
  SpaceTokenSpace = auto()
  Other = auto()

  def next(self, is_token, is_newline, is_space, can_standalone):
    if is_token:
      if self is State.Begin and can_standalone:
        return State.BeginToken
      elif self is State.Space and can_standalone:
        return State.SpaceToken
      else:
        return State.Other
    elif is_newline:
      return State.Begin
    elif is_space:
      if self is State.Begin:
        return State.Space
      elif self is State.BeginToken:
        return State.BeginTokenSpace
      elif self is State.SpaceToken:
        return State.SpaceTokenSpace
      else:
        return State.Other
    else: # is_print
      if self is State.Begin:
        return State.Print
      else:
        return State.Other

  @property
  def is_standalone(self):
    return self in (State.BeginToken,
                    State.SpaceToken,
                    State.BeginTokenSpace,
                    State.SpaceTokenSpace)
  @property
  def discard_before(self):
    return self in (State.SpaceToken,
                    State.SpaceTokenSpace)

  @property
  def discard_after(self):
    return self in (State.BeginTokenSpace,
                    State.SpaceTokenSpace)


class Parser:

  def __init__(self, start_delim='{{', end_delim='}}'):
    newline = r'\n|\r\n?'
    split_pat = r'({nl})|{start}((?:(?!{stop}).)*){stop}'.format(nl=newline,
                                                                 start=re.escape(start_delim),
                                                                 stop=re.escape(end_delim))
    self._split_pattern = re.compile(split_pat)
    self._types = ('', '&', '*', '#', '=', '?', '!', '|', '^', '/', '>')
    self._key_types = ('', '&', '*', '#', '=', '?', '!', '|', '^', '/')
    self._standalone_types = ('#', '=', '?', '!', '|', '^', '/')
    type_pat = r'[{chars}]{quant}'.format(chars=re.escape(''.join(self._types)),
                                          quant='?' if '' in self._types else '')
    self._token_pattern = re.compile(r'({type})\s*(\S+)\s*'.format(type=type_pat))
    self._space_pattern = re.compile(r'[ \t]+')
    # self._trailnl_pattern = re.compile(r'{nl}$'.format(nl=newline))

  def _decode_token(self, string):
    """

      raises ParserError for invalid token contents
    """
    m = self._token_pattern.fullmatch(string)
    if m is None:
      raise ParserError('Invalid token format "{}"'.format(string))
    type = m.group(1)
    param = m.group(2)
    if type in self._key_types:
      key = Key.parse(param)
      if key is None:
        raise ParserError('Invalid token key "{}"'.format(param))
      return (type, key)
    else:
      return (type, param)

  def _split(self, string):
    """
      Generate a raw item stream from a template string.

        ->(is_token, is_newline, is_space, content, (line, col))

      The template string is split into literals (whitespace or printable),
      newlines and tokens.
      Tokens are further decoded (see Parser._decode_token())
      into a type and parameter field.

      Each item is additionaly marked with its (line, column)-position
      within the template string.

      raises ParserError for invalid token contents
    """
    cursor = 0
    line = 0
    column_off = 0
    for match in self._split_pattern.finditer(string):
      m_newline = match.group(1)
      m_token = match.group(2)
      m_start = match.start()
      m_end = match.end()
      if cursor < m_start:
        content = string[cursor:m_start]
        pos = (line + 1, cursor - column_off + 1)
        is_space = self._space_pattern.fullmatch(content) is not None
        yield (False, False, is_space, content, pos)
      pos = (line + 1, m_start - column_off + 1)
      if m_newline is not None:
        yield (False, True, False, m_newline, pos)
        line += 1
        column_off = m_end
      else:
        try:
          yield (True, False, False, self._decode_token(m_token), pos)
        except ParserError as e:
          e.set_position(pos[0], pos[1])
          raise e
      cursor = m_end
    if cursor < len(string):
      content = string[cursor:]
      is_space = self._space_pattern.fullmatch(content) is not None
      pos = (line + 1, cursor - column_off + 1)
      yield (False, False, is_space, content, pos)


  def _filter(self, iterator):
    """
      Filter a raw item stream to decode standalone tokens.

        (is_token, is_newline, is_space, content, (line, col))
        -> (is_token, content, (line, col))

      The transformation is performed using a finite state machine (see State)
      which tracks item patterns at the beginning of a line and
      detects standalone tokens.
      Items are gathered in a queue for later modification,
      i.e. discarding whitespace around standalone tokens.
      This queue is flushed with each newline item.
    """
    state = State.Begin
    queue = deque()
    for is_token, is_newline, is_space, content, position in iterator:
      if is_token:
        # (is_token, content, position)
        queue.append((True, content, position))
      elif is_newline:
        # flush queue
        if state.is_standalone:
          if state.discard_before:
            queue.popleft()
          token = queue.popleft()
          if state.discard_after:
            queue.popleft()
          # queue should be empty now
          yield (True, token[1], token[2])
          # discard this newline item for standalone tokens
        else:
          while queue:
            yield queue.popleft()
          # pass this newline item for inline content
          yield (False, content, position)
      else:
        # append literal
        # (is_token, content, position)
        queue.append((False, content, position))
      can_standalone = is_token and content[0] in self._standalone_types
      state = state.next(is_token, is_newline, is_space, can_standalone)
    while queue:
      yield queue.popleft()

  def _parse(self, string):
    """
      Parse a template string into a token list ready for rendering

      raises ParserError for invalid token formats
      raises ParserError for inconsistent section tokens
    """
    sections = SectionStack()
    last_pos = (1,1)
    try:
      for is_token, content, pos in self._filter(self._split(string)):
        last_pos = pos
        if is_token:
          kind,param = content
          if kind == '':
            sections.append_token(ValueToken(param))
          elif kind == '&':
            sections.append_token(ValueToken(param, verbatim=True))
          elif kind == '*':
            sections.append_token(IndirectToken(param, self))
          elif kind == '>':
            sections.append_token(PartialToken(param))
          elif kind == '#':
            sections.push_normal(param, pos)
          elif kind == '=':
            sections.push_enter(param, pos)
          elif kind == '?':
            sections.push_check(param, pos)
          elif kind == '!':
            sections.push_exists(param, pos)
          elif kind == '^':
            sections.push_inverted(param, pos)
          elif kind == '|':
            sections.alternate(param, pos)
          elif kind == '/':
            key, truthy, falsey, mode = sections.pop(param)
            token = SectionToken(key, truthy, falsey, mode)
            sections.append_token(token)
        else:
          sections.append_literal(content)
      return sections.take()
    except ParserError as e:
      e.set_position(last_pos[0], last_pos[1])
      raise e

  def parse(self, string, name=None):
    try:
      return Template(self._parse(string), name)
    except ParserError as e:
      e.set_source(name)
      raise e


