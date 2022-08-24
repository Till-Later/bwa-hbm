import argparse
from itertools import chain
from pathlib import Path
import sys
import shutil
import traceback

from .configreader import ConfigReader
from .contextrenderer import ContextRenderer
from .util import DFACCTOError


def main(args):
  try:
    reader = ConfigReader()
    for config in args.config:
      reader.read(config)

    context = reader.context
    if args.debug:
      breakpoint()

    renderer = ContextRenderer(args.outdir)
    for tpldir in args.tpldir:
      renderer.load_templates(tpldir, args.tpl_suffix, args.part_suffix)

    for f in args.outdir.iterdir():
      if f.is_dir():
        shutil.rmtree(f)
      else:
        f.unlink()

    element_iter = chain((context,), context.packages.contents(), context.entities.contents())
    for element in element_iter:
      for tpl_name,out_name in element.props.get('templates', {}).items():
        element_name = '{}:{}'.format(type(element).__name__, str(element)) if element is not context else str(element)
        print('{:>24s} ---{:-^24s}---> {:<24s}'.format(tpl_name, element_name, out_name or tpl_name))
        renderer.render(tpl_name, element, out_name)

  except DFACCTOError as e:
    print(e, file=sys.stderr)
    return 1

  except Exception as e:
    print('Unexpected error:', file=sys.stderr)
    traceback.print_exc(file=sys.stderr)
    return 1

  return 0


def path_arg(arg, dir=True, exist=False):
  path = Path(arg).expanduser().resolve()
  if dir:
    if exist:
      if not path.is_dir():
        raise argparse.ArgumentTypeError('{} must be an existing directory'.format(path))
    else:
      try:
        path.mkdir(parents=True, exist_ok=True)
      except FileExistsError:
        raise argparse.ArgumentTypeError('{} must be a directory'.format(path))
    return path
  else:
    if exist:
      if not path.is_file():
        raise argparse.ArgumentTypeError('{} must be an existing file'.format(path))
    else:
      try:
        path.parent.mkdir(parents=True, exist_ok=True)
      except FileExistsError:
        raise argparse.ArgumentTypeError('Parents of {} are not directories'.format(path))
      if path.exists and not path.is_file():
        raise argparse.ArgumentTypeError('{} must be a file'.format(path))
    return path


if __name__ == "__main__":
  parser = argparse.ArgumentParser(
      prog='dfaccto_tpl',
      description='Build a data model from a config script and use it to render templates')

  parser.add_argument('--tpldir', required=False, action='append', default=[],
      type=lambda a: path_arg(a, dir=True, exist=True),
      metavar='<tpldir>',
      help='search for templates and partials here (can appear more than once)')

  parser.add_argument('--outdir', required=True, action='store',
      type=lambda a: path_arg(a, dir=True, exist=False),
      metavar='<outdir>',
      help='place generated files here (WARNING: deletes existing content!)')

  parser.add_argument('--config', required=True, action='append',
      type=lambda a: path_arg(a, dir=False, exist=True),
      metavar='<config>',
      help='read this script to build the data model (can appear more than once)')

  parser.add_argument('--tpl-suffix', required=False, action='store', default='.tpl',
      metavar='<tpl>',
      help='files ending in <tpl> under <tpldir> are used as templates or partials')

  parser.add_argument('--part-suffix', required=False, action='store', default='.part',
      metavar='<part>',
      help='files ending in <part><tpl> under <tpldir> are used as partials')

  parser.add_argument('--debug', action='store_true',
      help='enter debugger after scripts are read and before templates are rendered')

  sys.exit(main(parser.parse_args()))

