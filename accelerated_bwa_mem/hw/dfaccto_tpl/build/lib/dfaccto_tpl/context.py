from .entity import Entity
from .hasprops import HasProps
from .package import Package
from .util import DFACCTOError, Registry, safe_str



class Context(HasProps):

  def __init__(self):
    HasProps.__init__(self)
    self._packages = Registry()
    self._entities = Registry()
    self._identifiers = Registry()

  def __str__(self):
    return '<global>'

  @property
  def packages(self):
    return self._packages

  @property
  def entities(self):
    return self._entities

  @property
  def identifiers(self):
    return self._identifiers

  def clear(self):
    self.clear_props()
    self._packages.clear()
    self._entities.clear()
    self._identifiers.clear()

  def add_package(self, name):
    return Package(self, name)

  def get_package(self, name):
    if self._packages.has(name):
      return self._packages.lookup(name)
    else:
      raise DFACCTOError('Package reference "{}" can not be found'.format(name))

  def add_entity(self, name):
    return Entity(self, name)

  def get_entity(self, name):
    if self._entities.has(name):
      return self._entities.lookup(name)
    else:
      raise DFACCTOError('Entity reference "{}" can not be found'.format(name))

  def get_type(self, name, pkg_name=None):
    type = None
    if pkg_name is None:
      for pkg in self._packages.contents():
        if pkg.types.has(name):
          if type is not None:
            raise DFACCTOError('Unqualified type reference "{}" is ambiguous (Packages {}, {})'.format(name, pkg, type.package))
          else:
            type = pkg.types.lookup(name)
      if type is None:
        raise DFACCTOError('Unqualified type reference "{}" can not be found in any package'.format(name))
    else:
      pkg = self._packages.lookup(pkg_name)
      type = pkg.types.lookup(name)
    return type

  def get_constant(self, name, pkg_name=None):
    constant = None
    if pkg_name is None:
      for pkg in self._packages.contents():
        if pkg.constants.has(name):
          if constant is not None:
            raise DFACCTOError('Unqualified constant reference "{}" is ambiguous (Packages {}, {})'.format(name, pkg, constant.package))
          else:
            constant = pkg.constants.lookup(name)
      if constant is None:
        raise DFACCTOError('Unqualified constant reference "{}" can not be found in any package'.format(name))
    else:
      pkg = self._packages.lookup(pkg_name)
      constant = pkg.constants.lookup(name)
    return constant


