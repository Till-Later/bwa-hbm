from .errors import AbsentError



def _default_lookup(obj, field):
  try:
    idx = int(field)
    return obj[idx]
  except IndexError:
    raise AbsentError('Could not find index "{}"'.format(field))
  except (TypeError, ValueError):
    try:
      return obj[field]
    except KeyError:
      raise AbsentError('Could not find key "{}"'.format(field))
    except TypeError:
      try:
        return getattr(obj, field)
      except AttributeError:
        raise AbsentError('Could not find member "{}"'.format(field))


class Context:

  def __init__(self, *context_items, raise_on_absent=False, lookup=None, stringify=None, escape=None, partial=None):
    self._stack = list(context_items)
    self._raise_on_absent = raise_on_absent
    self._lookup = lookup or _default_lookup
    self._stringify = stringify or str
    self._escape = escape
    self._partial = partial

  def get_partial(self, name):
    partial = None
    if self._partial is not None:
      partial = self._partial(name)
    if partial is None and self._raise_on_absent:
      raise AbsentError('Can not resolve partial "{}"'.format(name))
    return partial

  def push(self, item):
    self._stack.append(item)

  def pop(self):
    return self._stack.pop()

  def get_string(self, key, verbatim):
    try:
      val = self._get_value(key)
      if not isinstance(val, str):
        val = self._stringify(val)
      if verbatim or self._escape is None:
        return val
      else:
        return self._escape(val)
    except AbsentError as e:
      if self._raise_on_absent:
        e.set_key(key)
        raise e
      else:
        return ''

  def get_iterable(self, key):
    try:
      val = self._get_value(key)
      if not val:
        return []
      elif isinstance(val, str):
        return [val]
      else:
        try:
          iter(val)
        except TypeError:
          return [val]
        else:
          return val
    except AbsentError as e:
      if self._raise_on_absent:
        e.set_key(key)
        raise e
      else:
        return []

  def has_value(self, key):
    try:
      self._get_value(key)
      return True
    except AbsentError as e:
      return False

  def get_value(self, key):
    try:
      return self._get_value(key)
    except AbsentError as e:
      if self._raise_on_absent:
        e.set_key(key)
        raise e
      else:
        return None

  def _get_value(self, key):
    value = self._get_first(key)
    for field in key.rest:
      value = self._lookup(value, field)
    return value

  def _get_first(self, key):
    end = -key.top if key.top > 0 else None
    start = -key.top - 1 if key.anchored else None

    slice = self._stack[start:end]
    if not slice:
      raise AbsentError('Not enough stack levels to start at {}'.format(key.top))
    if not key.first:
      return slice[-1]
    else:
      to_skip = key.skip
      for item in reversed(slice):
        try:
          val = self._lookup(item, key.first)
          if to_skip > 0:
            to_skip -= 1
          else:
            return val
        except AbsentError:
          pass
      raise AbsentError('Could not find {} in context stack after skipping {}'.format(key.first, key.skip - to_skip))


