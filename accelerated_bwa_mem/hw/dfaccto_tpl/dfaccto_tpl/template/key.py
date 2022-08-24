import re



class Key:
  """
  Represents a lookup key to get a value from a Context instance.

  It consists of a (possibly empty) path of field names to search for,
  as well as a mode parameter that modifies the search semantics.
  A negative mode values indicate anchored mode, where only the
  top of the Context stack is considered.
  A non-negative mode value results in a search through the entire
  Context stack, and indicates the number of matches that should be skipped.

  (See Context)
  """

  _Pattern = re.compile(r'([.]+)|([.]*)(\w+)([+]|[\']*)((?:\.\w+)*)')

  @classmethod
  def parse(cls, string):
    """
    Parse a string representation into a Key instance.

    The string is expected to be a dot . separated sequence of words,
    indicating a path of field names to search for in the Context.
    Leading dots . select anchored mode, with the number of dots
    indicating the position of the anchor item from the top of the context stack.
    A modifier after the first path element changes the search behavior:
    A plus + disables anchored mode so that all elements below the
    anchor on the stack will be searched as well.
    Any number of ticks ' also disable anchored mode, and also
    indicate the number of matches that should be skipped during the search.
    With leading dots . the path may be empty, indicating that the respective
    context stack item should be used as is without further search.

    Examples:
      ".."             Key(top=1, mode=-1, path=())
      "foo"    ".foo+" Key(top=0, mode=0,  path=('foo',))
      ".foo"           Key(top=0, mode=-1, path=('foo',))
      "foo'"   ".foo'" Key(top=0, mode=1   path=('foo',))
      "...foo+"        Key(top=2, mode=0,  path=('foo',))
      "..foo"          Key(top=1, mode=-1, path=('foo',))
      "..foo''"        Key(top=1, mode=2,  path=('foo',))
      "foo.bar.qux"    Key(top=0, mode=0,  path=('foo', 'bar', 'qux'))
      "..foo+.bar.qux" Key(top=1, mode=0,  path=('foo', 'bar', 'qux'))
      "foo''.bar.qux"  Key(top=0, mode=2,  path=('foo', 'bar', 'qux'))

    Parameters:
      string : str
        Key string representation to parse.
    Returns:
      Key instance if string is valid or None otherwise
    """
    if m := cls._Pattern.fullmatch(string):
      m_onlytop = m.group(1)
      m_top = m.group(2)
      m_mode = m.group(4)
      if m_onlytop is not None:
        top = len(m_onlytop) - 1
        return cls(top, mode=-1, path=())
      else:
        top = 0
        mode = 0
        if m_top:
          top = max(0, len(m_top) - 1)
          mode = -1
        if m_mode:
          mode = 0 if m_mode == '+' else len(m_mode)
        path = tuple((m.group(3) + m.group(5)).split('.'))
        return cls(top, mode, path)
    else:
      return None

  def __init__(self, top, mode, path):
    """
    Construct a Key instance with explicit mode and path parameters.

    Parameters:
      top  : int
        Begin search <top> items from the top of the context stack
      mode : int
        If >= 0, skip this number of matches (skip mode),
        if < 0, only consider a single item from the context stack (anchored mode)
      path : tuple(str)
        If empty, take the item identified by <top> directly from the context stack,
        if non-empty, search for the first key according to <top> and <mode>,
          then follow successive keys through lookups in the results
    """
    self._top = top
    self._mode = mode
    self._path = path

  @property
  def top(self):
    return self._top

  @property
  def mode(self):
    """Raw mode parameter"""
    return self._mode

  @property
  def anchored(self):
    """True for anchored mode"""
    return self._mode < 0

  @property
  def skip(self):
    """Number of matches to skip"""
    return max(self._mode, 0)

  @property
  def path(self):
    """Raw path parameter"""
    return self._path

  @property
  def first(self):
    """First component of path or None if empty"""
    return self._path and self._path[0] or None

  @property
  def rest(self):
    """Following components of path or empty if absent"""
    return self._path[1:]


  def __str__(self):
    top_str = '.' * (self.top + 1) if self.top or self.anchored else ''
    mode_str = '\'' * self.skip
    if not self.skip and self.top:
      mode_str = '+'
    first_str = self.first if self.first else ''
    rest_str = '.' + '.'.join(self.rest) if self.rest else ''
    return ''.join((top_str, first_str, mode_str, rest_str))

  def __eq__(self, other):
    return self._top == getattr(other, '_top', None) and self._mode == getattr(other, '_mode', None) and self._path == getattr(other, '_path', None)

  def __hash__(self):
    return hash((self._top, self._mode, self._path))


