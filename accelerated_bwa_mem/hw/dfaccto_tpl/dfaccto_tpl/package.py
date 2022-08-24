from .constant import Constant
from .element import Element, PackageElement
from .type import Type
from .util import Registry, safe_str, IndexWrapper, visit_usage_deps



class Package(Element):

  def __init__(self, context, name):
    Element.__init__(self, context, name, '{name}')

    self._types = Registry()
    self._constants = Registry()
    self._declarations = Registry()
    self._identifiers = Registry()

    self.context.packages.register(self.name, self)
    self.context.identifiers.register(self.identifier, self)

  def __str__(self):
    try:
      return self.name
    except:
      return safe_str(self)

  @property
  def has_role(self):
    return False

  @property
  def types(self):
    return self._types

  @property
  def constants(self):
    return self._constants

  @property
  def declarations(self):
    return self._declarations

  @property
  def identifiers(self):
    return self._identifiers

  @property
  def dependencies(self):
    deps = set()
    self.usage_deps(deps, set())
    return IndexWrapper(deps)

  def usage_deps(self, deps, visited):
    self.prop_deps(deps, visited)
    for element in self._identifiers.contents():
      visit_usage_deps(deps, visited, element)
    deps.remove(self)

  def add_type(self, name, is_complex):
    return Type(self, name, is_complex)

  def add_constant(self, name, type, size, value):
    return Constant(self, name, type, size, value)

  def get_type(self, name, pkg_name=None):
    if pkg_name is None and self.types.has(name):
      return self.types.lookup(name)
    else:
      return self.context.get_type(name, pkg_name)

  def get_constant(self, name, pkg_name=None):
    if pkg_name is None and self.constants.has(name):
      return self.constants.lookup(name)
    else:
      return self.context.get_constant(name, pkg_name)


