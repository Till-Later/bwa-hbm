from .assignable import ConstAssignable
from .assignment import Assignment
from .element import EntityElement
from .typed import Typed
from .role import Role
from .util import safe_str



class Generic(EntityElement, Typed, ConstAssignable):
  def __init__(self, entity, name, type, size_generic):
    if size_generic is not None:
      # Generics used for size must be simple scalars
      size_generic.role_equals(Role.Simple)
      size_generic.vector_equals(False)

    EntityElement.__init__(self, entity, name, 'g_{name}{dir}', inst_type=InstGeneric)
    Typed.__init__(self, Role.Const, type, size_generic is not None, size_generic)
    ConstAssignable.__init__(self)

    self.entity.generics.register(self.name, self)
    if self.is_simple:
      self.entity.identifiers.register(self.identifier, self)
    elif self.is_complex:
      self.entity.identifiers.register(self.identifier_ms, self)
      self.entity.identifiers.register(self.identifier_sm, self)

  def __str__(self):
    try:
      if self.is_vector:
        return '({}).g_{}:{}({})'.format(self.entity, self.name, self.type, self.size)
      else:
        return '({}).g_{}:{}'.format(self.entity, self.name, self.type)
    except:
      return safe_str(self)

  def usage_deps(self, deps, visited):
    EntityElement.usage_deps(self, deps, visited)
    Typed.usage_deps(self, deps, visited)


class InstGeneric(EntityElement, Assignment):
  def __init__(self, generic, inst_entity):
    size = inst_entity.generics.lookup(generic.size.name) if generic.is_vector else None

    EntityElement.__init__(self, inst_entity, generic.name, 'g_{name}{dir}', base=generic)
    # size.raw_value may be DeferredValue and will propagate if necessary
    Assignment.__init__(self, ConstAssignable, generic.role, generic.type, size is not None, size and size.raw_value)

    self.entity.generics.register(self.name, self)
    if self.is_simple:
      self.entity.identifiers.register(self.identifier, self)
    elif self.is_complex:
      self.entity.identifiers.register(self.identifier_ms, self)
      self.entity.identifiers.register(self.identifier_sm, self)

  def __str__(self):
    try:
      if self.is_vector:
        if self.is_assigned:
          return '({}).g_{}:{}({})=>{}'.format(self.entity, self.name, self.type, self.size, self.raw_value)
        else:
          return '({}).g_{}:{}({})'.format(self.entity, self.name, self.type, self.size)
      else:
        if self.is_assigned:
          return '({}).g_{}:{}=>{}'.format(self.entity, self.name, self.type, self.raw_value)
        else:
          return '({}).g_{}:{}'.format(self.entity, self.name, self.type)
    except:
      return safe_str(self)

  def usage_deps(self, deps, visited):
    EntityElement.usage_deps(self, deps, visited)
    Assignment.usage_deps(self, deps, visited)

