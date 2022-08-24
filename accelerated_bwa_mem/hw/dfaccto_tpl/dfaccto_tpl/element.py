from .hasprops import HasProps
from .util import cached_property



class Element(HasProps):
  def __init__(self, context, name, ident_fmt, has_vector=False):
    HasProps.__init__(self)
    self._context = context
    self._name = name
    self._ident_fmt = ident_fmt
    self._has_vector = has_vector

  @property
  def context(self):
    return self._context

  @property
  def name(self):
    return self._name

  @cached_property
  def identifier(self):
    if self.has_role:
      if self.role.knows_complex and self.role.is_simple:
        return self._ident_fmt.format(name=self._name,
                                      mode=self.role.cmode or '',
                                      vec='', dir='')
    else:
      return self._ident_fmt.format(name=self._name,
                                    mode='',
                                    vec='', dir='')

  @cached_property
  def identifier_ms(self):
    if self.has_role and self.role.knows_complex and self.role.is_complex:
      return self._ident_fmt.format(name=self._name,
                                    mode=self.role.cmode_ms or '',
                                    vec='', dir='_ms')

  @cached_property
  def identifier_sm(self):
    if self.has_role and self.role.knows_complex and self.role.is_complex:
      return self._ident_fmt.format(name=self._name,
                                    mode=self.role.cmode_sm or '',
                                    vec='', dir='_sm')

  @cached_property
  def identifier_v(self):
    if self._has_vector:
      if self.has_role:
        if self.role.knows_complex and self.role.is_simple:
          return self._ident_fmt.format(name=self._name,
                                        mode=self.role.cmode or '',
                                        vec='_v', dir='')
      else:
        return self._ident_fmt.format(name=self._name,
                                      mode='',
                                      vec='_v', dir='')

  @cached_property
  def identifier_v_ms(self):
    if self._has_vector and self.has_role and self.role.knows_complex and self.role.is_complex:
      return self._ident_fmt.format(name=self._name,
                                    mode=self.role.cmode_ms or '',
                                    vec='_v', dir='_ms')

  @cached_property
  def identifier_v_sm(self):
    if self._has_vector and self.has_role and self.role.knows_complex and self.role.is_complex:
        return self._ident_fmt.format(name=self._name,
                                      mode=self.role.cmode_sm or '',
                                      vec='_v', dir='_sm')


class EntityElement(Element):
  def __init__(self, entity, name, ident_fmt, base=None, inst_type=None):
    Element.__init__(self, entity.context, name, ident_fmt)
    self._entity = entity
    self._base = base
    self._inst_type = inst_type

  @property
  def entity(self):
    return self._entity

  @property
  def base(self):
    return self._base

  @property
  def is_instance(self):
    return self._base is not None

  @property
  def qualified(self):
    return self.identifier

  @property
  def qualified_ms(self):
    return self.identifier_ms

  @property
  def qualified_sm(self):
    return self.identifier_sm

  @property
  def qualified_v(self):
    return self.identifier_v

  @property
  def qualified_v_ms(self):
    return self.identifier_v_ms

  @property
  def qualified_v_sm(self):
    return self.identifier_v_sm

  def instantiate(self, inst_entity):
    if self._inst_type is None:
      raise DFACCTOError('Can not instantiate {}'.format(self))
    return self._inst_type(self, inst_entity)

  def usage_deps(self, deps, visited):
    self.prop_deps(deps, visited)



class PackageElement(Element):
  def __init__(self, package, name, ident_fmt, has_vector=False):
    Element.__init__(self, package.context, name, ident_fmt, has_vector)
    self._package = package

  @property
  def package(self):
    return self._package

  @cached_property
  def qualified(self):
    ident = self.identifier
    if ident is not None:
      return '{}.{}'.format(self.package.identifier, ident)

  @cached_property
  def qualified_ms(self):
    ident = self.identifier_ms
    if ident is not None:
      return '{}.{}'.format(self.package.identifier, ident)

  @cached_property
  def qualified_sm(self):
    ident = self.identifier_sm
    if ident is not None:
      return '{}.{}'.format(self.package.identifier, ident)

  @cached_property
  def qualified_v(self):
    ident = self.identifier_v
    if ident is not None:
      return '{}.{}'.format(self.package.identifier, ident)

  @cached_property
  def qualified_v_ms(self):
    ident = self.identifier_v_ms
    if ident is not None:
      return '{}.{}'.format(self.package.identifier, ident)

  @cached_property
  def qualified_v_sm(self):
    ident = self.identifier_v_sm
    if ident is not None:
      return '{}.{}'.format(self.package.identifier, ident)

  def usage_deps(self, deps, visited):
    self.prop_deps(deps, visited)
    deps.add(self.package)


