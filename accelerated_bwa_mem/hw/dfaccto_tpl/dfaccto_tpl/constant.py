from .assignable import ConstAssignable
from .assignment import Assignment
from .element import PackageElement
from .role import Role
from .util import safe_str, visit_usage_deps



class Constant(PackageElement, Assignment, ConstAssignable):
  def __init__(self, package, name, type, size_constant, value=None):
    if size_constant is not None:
      # Constants used for size must be simple scalars
      size_constant.role_equals(Role.Simple)
      size_constant.vector_equals(False)

    PackageElement.__init__(self, package, name, 'c_{name}{dir}')
    Assignment.__init__(self, ConstAssignable, Role.Const, type, size_constant is not None, size_constant and size_constant.raw_value, value)
    ConstAssignable.__init__(self)
    self._size_constant = size_constant

    self.package.constants.register(self.name, self)
    decl_name = self.package.declarations.unique_name(self.name) # Avoid collisions with type names
    self.package.declarations.register(decl_name, self)
    if self.is_complex:
      self.package.identifiers.register(self.identifier_ms, self)
      self.package.identifiers.register(self.identifier_sm, self)
    else:
      self.package.identifiers.register(self.identifier, self)

  def __str__(self):
    try:
      if self.is_vector:
        return '({}).c_{}:{}({}):={}'.format(self.package, self.name, self.type, self.size_constant, self.raw_value)
      else:
        return '({}).c_{}:{}:={}'.format(self.package, self.name, self.type, self.raw_value)
    except:
      return safe_str(self)

  @property
  def size_constant(self):
    return self._size_constant

  def usage_deps(self, deps, visited):
    PackageElement.usage_deps(self, deps, visited)
    Assignment.usage_deps(self, deps, visited)

