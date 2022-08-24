from .util import visit_usage_deps


class HasProps:
  def __init__(self):
    self._props = dict()

  def __getattr__(self, key):
    if key.startswith('x_') and key[2:] in self._props:
      return self._props[key[2:]]
    elif key.startswith('is_a_'):
      name = key[5:].lower()
      return any(name == cls.__name__.lower() for cls in type(self).mro())
    elif key.startswith('P_') and hasattr(self, 'packages'):
      return self.packages[key[2:]]
    elif key.startswith('c_') and hasattr(self, 'constants'):
      return self.constants[key[2:]]
    elif key.startswith('t_') and hasattr(self, 'types'):
      return self.types[key[2:]]
    elif key.startswith('E_') and hasattr(self, 'entities'):
      return self.entities[key[2:]]
    elif key.startswith('g_') and hasattr(self, 'generics'):
      return self.generics[key[2:]]
    elif key.startswith('p_') and hasattr(self, 'ports'):
      return self.ports[key[2:]]
    elif key.startswith('i_') and hasattr(self, 'instances'):
      return self.instances[key[2:]]
    else:
      raise AttributeError(key)

  def set_prop(self, key, value):
    self._props[key] = value

  # -> see Frontend.global_statement()
  # def update_prop(self, key, value):
  #   if key in self._props:
  #     old = self._props[key]
  #     try:
  #       old.update(value)
  #       return
  #     except:
  #       try:
  #         old.extend(value)
  #         return
  #       except:
  #         pass
  #   self._props[key] = value

  def clear_props(self):
    self._props.clear()

  @property
  def props(self):
    return self._props

  def prop_deps(self, deps, visited):
    for value in self._props.values():
      visit_usage_deps(deps, visited, value)


