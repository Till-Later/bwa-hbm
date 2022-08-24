import collections.abc as abc



class DFACCTOError(Exception):
  def __init__(self, msg):
    self.msg = msg


def safe_str(obj):
  try:
    var_strs = ('{}={}'.format(k,v) for k,v in vars(obj).items())
    return '{}({})'.format(type(obj).__name__, ' '.join(var_strs))
  except:
    return repr(obj)


class cached_property:
  def __init__(self, func):
    self._func = func

  def __get__(self, obj, cls):
    value = self._func(obj)
    if value is not None:
      obj.__dict__[self._func.__name__] = value
    return value


class IndexedObj():
  def __init__(self, obj, idx, len):
    self._obj = obj
    self._idx = idx
    self._len = len

  def __getattr__(self, key):
    try:
      return self._obj[key]
    except TypeError:
      pass
    except KeyError:
      pass
    if hasattr(self._obj, key):
      return getattr(self._obj, key)
    else:
      raise AttributeError

  def __str__(self):
    return str(self._obj)

  @property
  def _last(self):
    return self._idx == (self._len - 1)

  @property
  def _first(self):
    return self._idx == 0

class IndexIter():
  def __init__(self, lst):
    self._iter = iter(lst)
    self._idx = 0
    self._len = len(lst)

  def __next__(self):
    item = IndexedObj(next(self._iter), self._idx, self._len)
    self._idx += 1
    return item

class IndexWrapper():
  def __init__(self, lst):
    self._lst = lst

  def __iter__(self):
    return IndexIter(self._lst)

  @property
  def _len(self):
    return len(self._lst)


class Registry(abc.Iterable):
  def __init__(self):
    self._contents = list()
    self._names = dict()
    self._idx_cache = dict()

  def clear(self):
    self._contents.clear()
    self._names.clear()
    self._idx_cache.clear()

  def __iter__(self):
    return IndexIter(self._contents)

  def __len__(self):
    return len(self._contents)

  def __getitem__(self, key):
    try:
      return self._contents[key]
    except TypeError:
      idx = self._names[key]
      return self._contents[idx]

  def register(self, name, obj):
    if name in self._names:
      msg = 'Name collision: "{}" is already defined'.format(name)
      raise DFACCTOError(msg)
    self._names[name] = len(self._contents)
    self._contents.append(obj)

  def lookup(self, name):
    if name not in self._names:
      msg = 'Unresolved reference: "{}" is not defined'.format(name)
      raise DFACCTOError(msg)
    idx = self._names[name]
    return self._contents[idx]

  def has(self, name):
    return name in self._names

  def names(self):
    return self._names.keys()

  def contents(self):
    return tuple(self._contents)

  def items(self):
    for key,idx in self._names.items():
      yield key, self._contents[idx]

  def unique_name(self, prefix):
    idx = self._idx_cache.get(prefix, 0)
    candidate = prefix
    while candidate in self._names:
      candidate = '{}_{:d}'.format(prefix, idx)
      idx += 1
      self._idx_cache[prefix] = idx
    return candidate


class UnionFind:
  def __init__(self):
    self._root = list()
    self._groups = dict()

  def new(self):
    idx = len(self._root)
    self._root.append(idx)
    self._groups[idx] = set((idx,))
    return idx

  def find(self, idx):
    return self._root[idx]

  def group(self, idx):
    root = self.find(idx)
    return self._groups[root]

  def union(self, idx_a, idx_b):
    root_a = self.find(idx_a)
    root_b = self.find(idx_b)
    if root_a == root_b:
      return root_a

    for idx in self._groups[root_b]:
      self._root[idx] = root_a
      self._groups[root_a].add(idx)
    del self._groups[root_b]
    return root_a


class DeferredValue:
  _registry = UnionFind()
  _callbacks = dict()
  _values = dict()

  @classmethod
  def _create(cls, callback):
    idx = cls._registry.new()
    cls._callbacks[idx] = callback
    return idx

  @classmethod
  def _notify(cls, idx, value):
    for i in cls._registry.group(idx):
      callback = cls._callbacks.get(i)
      if callback:
        callback(value)

  @classmethod
  def _assign(cls, idx_a, idx_b):
    root_a = cls._registry.find(idx_a)
    root_b = cls._registry.find(idx_b)
    if root_a in cls._values and root_b in cls._values:
      raise ValueError('Can not assign already resolved values')
    elif root_a in cls._values:
      val_a = cls._values[root_a]
      cls._notify(idx_b, val_a)
      cls._registry.union(idx_a, idx_b)
    elif root_b in cls._values:
      val_b = cls._values[root_b]
      cls._notify(idx_a, val_b)
      cls._registry.union(idx_b, idx_a)
    else:
      cls._registry.union(idx_b, idx_a)

  @classmethod
  def _resolve(cls, idx, value):
    root = cls._registry.find(idx)
    if root in cls._values:
      raise ValueError('Can not resolve already resolved value')
    cls._notify(idx, value)
    cls._values[root] = value

  def __init__(self, on_resolve):
    self._idx = self._create(on_resolve)

  def assign(self, other):
    if isinstance(other, DeferredValue):
      self._assign(self._idx, other._idx)
    else:
      self._resolve(self._idx, other)


def visit_usage_deps(deps, visited, value):
  value_id = id(value)
  if value_id not in visited and hasattr(value, 'usage_deps'):
    visited.add(value_id)
    value.usage_deps(deps, visited)
