import re
from functools import partial
from collections import namedtuple
from enum import Enum, auto

from .entity import Entity
from .package import Package
from .role import Role
from .type import Type
from .typed import Literal
from .util import DFACCTOError, IndexWrapper



PortDeclaration = namedtuple('PortDeclaration', ('role', 'name', 'type', 'size_str', 'props'), defaults=(None, ()))

GenericDeclaration = namedtuple('GenericDeclaration', ('name', 'type', 'size_str', 'props'), defaults=(None, ()))

PortAssignment = namedtuple('PortAssignment', ('name', 'to', 'props'), defaults=(()))

GenericAssignment = namedtuple('GenericAssignment', ('name', 'to', 'props'), defaults=(()))


class RefKind(Enum):
  Package = auto()
  Type = auto()
  Constant = auto()
  #Function = auto()
  Entity = auto()
  Generic = auto()
  Signal = auto()


class ContextWrapper:
  def __init__(self, frontend, element):
    self._frontend = frontend
    self._element = element

  def __getattr__(self, key):
    return getattr(self._element, key)

  def __str__(self):
    return str(self._element)

  def __enter__(self):
    self._frontend.enter_context(self._element)

  def __exit__(self, type, value, trackback):
    self._frontend.leave_context()

  def unwrap(self):
    return self._element


class Frontend:

  NamePattern = re.compile('(\w+)')
  @classmethod
  def name_value(cls, value):
    if not isinstance(value, str):
      raise DFACCTOError('Name must be a string')
    if m := cls.NamePattern.fullmatch(value):
      return m.group(1)
    else:
      raise DFACCTOError('Invalid name "{}"'.format(value))

  PropPattern = re.compile('x_(\w+)')
  @classmethod
  def read_props(cls, directives):
    props = list()
    for key,val in directives.items():
      if (m := cls.PropPattern.fullmatch(key)) is not None:
        props.append((m.group(1), val))
      else:
        raise DFACCTOError('Invalid directive "{}"'.format(key))
    return props

  def __init__(self, context):
    self._context = context
    self._package = None
    self._entity = None
    self._namespace = {
      'List':      IndexWrapper,
      'Lit':       self.literal,
      'LitV':      self.literal_vector,
      'P':         partial(self.reference, RefKind.Package),
      'T':         partial(self.reference, RefKind.Type),
      'C':         partial(self.reference, RefKind.Constant),
      'E':         partial(self.reference, RefKind.Entity),
      'G':         partial(self.reference, RefKind.Generic),
      'S':         partial(self.reference, RefKind.Signal),
      'CV':        partial(self.vector_reference, RefKind.Constant),
      'GV':        partial(self.vector_reference, RefKind.Generic),
      'SV':        partial(self.vector_reference, RefKind.Signal),
      'Gbl':       self.global_statement,
      'Pkg':       self.package_declaration,
      'TypeS':     partial(self.type_declaration, False),
      'TypeC':     partial(self.type_declaration, True),
      'Con':       self.constant_declaration,
      'Ent':       self.entity_declaration,
      'Generic':   self.generic_declaration,
      'PortI':     partial(self.port_declaration, Role.Input),
      'PortO':     partial(self.port_declaration, Role.Output),
      'PortS':     partial(self.port_declaration, Role.Slave),
      'PortM':     partial(self.port_declaration, Role.Master),
      'PortV':     partial(self.port_declaration, Role.View),
      'PortP':     partial(self.port_declaration, Role.Pass),
      'Ins':       self.instance_declaration,
      'MapPort':   self.port_assignment,
      'MapGeneric': self.generic_assignment}

  @property
  def namespace(self):
    return self._namespace

  def enter_context(self, element):
    if not self.in_global_context:
      raise DFACCTOError('Can not nest contexts')
    if isinstance(element, Package):
      self._package = element
    elif isinstance(element, Entity):
      self._entity = element
    else:
      raise DFACCTOError('Can not use {} as new context'.format(element))

  def leave_context(self):
    self._package = None
    self._entity = None

  @property
  def in_global_context(self):
    return self._package is None and self._entity is None

  @property
  def in_package_context(self):
    return self._package is not None

  @property
  def in_entity_context(self):
    return self._entity is not None

  def _unpack_value(self, value, arg):
    value = value(arg) if callable(value) else value
    value = value.unwrap() if isinstance(value, ContextWrapper) else value
    return value

  def literal(self, val, type=None, expand=None):
    if type is not None and not isinstance(type, Type):
      raise DFACCTOError('Invalid literal type "{}"'.format(type))
    if expand is not None and isinstance(val, str):
      return Literal(val.format(expand), type)
    else:
      return Literal(val, type)

  def literal_vector(self, *vals, type=None, expand=None):
    if type is not None and not isinstance(type, Type):
      raise DFACCTOError('Invalid literal type "{}"'.format(type))
    if expand is not None:
      return tuple(Literal(val.format(e), type) for e in expand for val in vals)
    else:
      return tuple(Literal(val, type) for val in vals)

  def reference(self, kind, name, pkg=None, expand=None):
    name = self.name_value(name.format(expand) if expand is not None else name)
    if pkg is not None:
      pkg = self.name_value(pkg.format(expand) if expand is not None else pkg)
    if kind == RefKind.Package:
      if pkg is not None:
        raise DFACCTOError('Can not reference package "{}" within package "{}"'.format(name, pkg))
      return ContextWrapper(self, self._context.get_package(name))
    elif kind == RefKind.Type:
      if self._package is not None:
        return self._package.get_type(name, pkg)
      else:
        return self._context.get_type(name, pkg)
    elif kind == RefKind.Constant:
      if self._package is not None:
        return self._package.get_constant(name, pkg)
      else:
        return self._context.get_constant(name, pkg)
    elif kind == RefKind.Entity:
      if pkg is not None:
        raise DFACCTOError('Can not reference entity "{}" within package "{}"'.format(name, pkg))
      return ContextWrapper(self, self._context.get_entity(name))
    elif kind == RefKind.Generic:
      if pkg is not None:
        raise DFACCTOError('Can not reference generic "{}" within package "{}"'.format(name, pkg))
      if self._entity is None:
        raise DFACCTOError('Can not reference generic "{}" outside entity context'.format(name))
      return self._entity.get_generic(name)
    elif kind == RefKind.Signal:
      if pkg is not None:
        raise DFACCTOError('Can not reference port/signal "{}" within package "{}"'.format(name, pkg))
      if self._entity is None:
        raise DFACCTOError('Can not reference port/signal "{}" outside entity context'.format(name))
      return self._entity.get_connectable(name)
    else:
      raise DFACCTOError('Invalid kind of reference "{}"'.format(kind))

  def vector_reference(self, kind, *names, pkg=None, expand=None):
    if expand is not None:
      return tuple(self.reference(kind, name, pkg, e) for e in expand for name in names)
    else:
      return tuple(self.reference(kind, name, pkg) for name in names)

  def global_statement(self, **directives):
    if not self.in_global_context:
      raise DFACCTOError('Global statement must appear in the global context')
    props = self.read_props(directives)

    for name, value in props:
      self._context.set_prop(name, self._unpack_value(value, self._context))
    # TODO-lw deep update, so that multiple Gbl(x_templates={...}) extend templates dir!

  def package_declaration(self, name, **directives):
    if not self.in_global_context:
      raise DFACCTOError('Package declaration must appear in the global context')
    name = self.name_value(name)
    props = self.read_props(directives)

    package = self._context.add_package(name)
    for name, value in props:
      package.set_prop(name, self._unpack_value(value, package))

    return ContextWrapper(self, package)

  def type_declaration(self, is_complex, name, **directives):
    if not self.in_package_context:
      raise DFACCTOError('Type declaration must appear in a package context')
    name = self.name_value(name)
    props = self.read_props(directives)

    type = self._package.add_type(name, is_complex)
    for name, value in props:
      type.set_prop(name, self._unpack_value(value, type))

    return type

  def constant_declaration(self, name, type, vector=None, value=None, **directives):
    if not self.in_package_context:
      raise DFACCTOError('Constant declaration must appear in a package context')
    name = self.name_value(name)
    if not isinstance(type, Type):
      raise DFACCTOError('Invalid type "{}" in constant declaration'.format(type))
    if vector is not None:
      vector = self._package.get_constant(vector, self._package.name)
    props = self.read_props(directives)

    constant = self._package.add_constant(name, type, vector, value)
    for name, value in props:
      constant.set_prop(name, self._unpack_value(value, constant))

    return constant

  def entity_declaration(self, name, *decls, **directives):
    if not self.in_global_context:
      raise DFACCTOError('Entity declaration must appear in the global context')
    name = self.name_value(name)
    props = self.read_props(directives)
    part_props = []

    entity = self._context.add_entity(name)
    for decl in decls:
      if isinstance(decl, GenericDeclaration):
        size = entity.get_generic(decl.size_str) if decl.size_str is not None else None
        generic = entity.add_generic(decl.name, decl.type, size)
        if decl.props:
          part_props.append((generic, decl.props))
      elif isinstance(decl, PortDeclaration):
        size = entity.get_generic(decl.size_str) if decl.size_str is not None else None
        port = entity.add_port(decl.name, decl.role, decl.type, size)
        if decl.props:
          part_props.append((port, decl.props))
      else:
        raise DFACCTOError('Unexpected parameter "{}" in entity declaration'.format(decl))
    for part, pprops in part_props:
      for name, value in pprops:
        part.set_prop(name, self._unpack_value(value, entity))
    for name, value in props:
      entity.set_prop(name, self._unpack_value(value, entity))

    return ContextWrapper(self, entity)

  def generic_declaration(self, name, type, vector=None, **directives):
    if not isinstance(type, Type):
      raise DFACCTOError('Invalid type "{}" in generic declaration'.format(type))
    props = self.read_props(directives)
    return GenericDeclaration(self.name_value(name), type, vector, props)

  def port_declaration(self, role, name, type, vector=None, **directives):
    if not isinstance(type, Type):
      raise DFACCTOError('Invalid type "{}" in generic declaration'.format(type))
    props = self.read_props(directives)
    return PortDeclaration(role, self.name_value(name), type, vector, props)

  def instance_declaration(self, entity_name, name, *decls, **directives):
    if not self.in_entity_context:
      raise DFACCTOError('Instance declaration must appear in an entity context')
    entity_name = self.name_value(entity_name)
    if name is None:
      name = entity_name[0].lower() + entity_name[1:]
    inst_name = self._entity.instances.unique_name(name)
    props = self.read_props(directives)
    part_props = []

    entity = self._context.get_entity(entity_name)
    instance = entity.instantiate(self._entity, inst_name)
    for decl in decls:
      if isinstance(decl, GenericAssignment):
        inst_generic = instance.assign_generic(decl.name, decl.to)
        if decl.props:
          part_props.append((inst_generic, decl.props))
      elif isinstance(decl, PortAssignment):
        inst_port = instance.assign_port(decl.name, decl.to)
        if decl.props:
          part_props.append((inst_port, decl.props))
      else:
        raise DFACCTOError('Unexpected parameter "{}" in instance declaration'.format(decl))
    for part, props in part_props:
      for name, value in props:
        part.set_prop(name, self._unpack_value(value, instance))
    for name, value in props:
      instance.set_prop(name, self._unpack_value(value, instance))

    return instance

  def generic_assignment(self, name, to, **directives):
    return GenericAssignment(self.name_value(name), to, self.read_props(directives))

  def port_assignment(self, name, to, **directives):
    return PortAssignment(self.name_value(name), to, self.read_props(directives))


