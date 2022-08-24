# dfaccto_tpl
Specify structural hardware designs in Python and generate HDL sources from templates

## Introduction

This Python package provides a data model for structural hardware designs, as well as a frontend for specifying such models through python code.
Such models are intended as a context for rendering templates in a hardware description language such as VHDL or Verilog.
The terminology in this project is based on VHDL, but as the structural modeling concepts in both languages do not differ that much, you might also use it for generating Verilog sources.

A very rough overview of the data model looks as follows:
 * Package
   * Type
 * Entity
   * Generic
   * Port
   * Instance (-> Entity)
   * Signal

The root is a collection of packages and entities.
A package contains type definitions that can be used for signals and ports.
A simple type may be composite, like a VHDL `array` or `record`, but ports of this type will involve a single signal direction (`in` or `out`).
In contrast, complex types are composites where different parts have different directions.
Such a type might for example characterize a handshake port.
On the HDL level, a complex type is split into two separate types for each bundle of opposite signal directions.

An entity is a piece of hardware with a defined interface, which can be instantiated in another entity.
The interface is composed of generics and ports, with semantics analogous to VHDL.
The inner structure of an entity can be left opaque, if it will be implemented in custom HDL code.
On the other hand, it might also be used as a context to instantiate and connect entities in.
This information may later be used to generate the equivalent instantiation code automatically.

