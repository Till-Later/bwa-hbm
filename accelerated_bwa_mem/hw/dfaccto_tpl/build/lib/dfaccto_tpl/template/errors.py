


class TemplateError(Exception):
  pass

class ParserError(TemplateError):
  def __init__(self, msg, source=None, line=None, column=None):
    self._msg = msg
    self._source = source
    self._line = line
    self._column = column

  def set_source(self, source):
    self._source = source

  def set_position(self, line=None, column=None):
    self._line = line if line is not None else self._line
    self._column = column if column is not None else self._column

  def __str__(self):
    source_str = None if self._source is None else str(self._source)
    line_str = None if self._line is None else str(self._line)
    column_str = None if self._column is None else str(self._column)
    pos_str = ':'.join(filter(lambda s: s is not None, (source_str, line_str, column_str)))
    if pos_str:
      pos_str = ' at [{}]:\n'.format(pos_str)
    else:
      pos_str = ':'
    return 'ParserError{} {}'.format(pos_str, self._msg)

class AbsentError(TemplateError):
  def __init__(self, msg=None, key=None):
    self._msg = msg
    self._key = key

  def set_key(self, key):
    self._key = key

  def __str__(self):
    msg_str = self._msg or 'Could not resolve value'
    key_str = ''
    if self._key is not None:
      key_str = ' for key "{}"'.format(self.key)
    return '{}{}'.format(msg_str, key_str)

