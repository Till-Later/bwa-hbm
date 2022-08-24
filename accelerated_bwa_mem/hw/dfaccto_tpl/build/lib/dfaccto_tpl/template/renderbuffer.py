from io import StringIO
import re


class RenderBuffer:

  _NL = re.compile(r'\n|\r\n?')
  @classmethod
  def split(cls, string):
    # yield (line, has_newline, last_newline, last_partline)
    idx = 0
    cur_line = None
    for m in cls._NL.finditer(string):
      if cur_line is not None:
        yield (cur_line, True, False, False)
      end = m.end()
      cur_line = string[idx:end]
      idx = end
    if cur_line is not None:
      yield (cur_line, True, True, False)
    if idx < len(string):
      yield (string[idx:], False, False, True)

  _NS = re.compile(r'\S')
  @classmethod
  def spacify(cls, string):
    return cls._NS.sub(' ', string)

  _TNL = re.compile(r'(?:\n|\r\n?)$')
  @classmethod
  def without_trailing(cls, string):
    return cls._TNL.sub('', string)

  def __init__(self, stream=None, no_indent=False):
    self._buffer = stream or StringIO(newline='')
    self._pre_buffer = None
    self._in_memory = stream is None
    self._no_indent = no_indent
    self._indent_stack = []
    self._current_line = []
    self._first = False

  @property
  def _indent(self):
    if self._indent_stack:
      return self._indent_stack[-1]
    else:
      return ''

  def _write_indent(self):
    for line, has_newline, last_newline, last_partline in self.split(self._pre_buffer):
      self._buffer.write(line)
      if has_newline:
        self._buffer.write(self._indent)
      if last_newline:
        self._current_line.clear()
        self._current_line.append(self._indent)
      if last_partline:
        self._current_line.append(line)

  def _write_plain(self):
    self._buffer.write(self._pre_buffer)

  def write(self, string):
    if self._pre_buffer is not None:
      if self._no_indent:
        self._write_plain()
      else:
        self._write_indent()
    self._pre_buffer = string

  def remove_trailing(self):
    if self._pre_buffer is not None:
      self._pre_buffer = self.without_trailing(self._pre_buffer)

  def push_indent(self):
    self.write(None) # flush _pre_buffer
    if not self._no_indent:
      self._indent_stack.append(self.spacify(''.join(self._current_line)))

  def pop_indent(self):
    if not self._no_indent:
      self._indent_stack.pop()

  def finish(self):
    self.write(None) # flush _pre_buffer
    if self._in_memory:
      return self._buffer.getvalue()


