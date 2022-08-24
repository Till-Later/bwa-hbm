from pathlib import Path

from .template import parse, TemplateError
from .util import DFACCTOError



class ContextRenderer:
  def __init__(self, out_path):
    self._out_path = Path(out_path)
    self._templates = dict()
    self._partials = dict()

  def load_template(self, tpl_path, tpl_name, is_partial=False):
    tpl_path = Path(tpl_path)
    tpl_string = tpl_path.read_text()
    try:
      if is_partial:
        self._partials[tpl_name] = parse(tpl_string, tpl_name)
      else:
        self._templates[tpl_name] = parse(tpl_string, tpl_name)
    except TemplateError as e:
      raise DFACCTOError(str(e))

  def load_templates(self, search_path, tpl_suffix, partial_suffix=None):
    search_path = Path(search_path)
    for tpl_file in search_path.rglob('*{}'.format(tpl_suffix)):
      name = str(tpl_file.relative_to(search_path))[:-len(tpl_suffix)]
      is_partial = partial_suffix is not None and name.endswith(partial_suffix)
      self.load_template(tpl_file, name, is_partial)

  def render(self, tpl_name, context, out_name=None):
    if tpl_name not in self._templates:
      raise DFACCTOError('Error: unknown template "{}"'.format(tpl_name))
    template = self._templates[tpl_name]
    path = self._out_path / (out_name or tpl_name)
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
      raise DFACCTOError('Error: would override existing file "{}"'.format(path))
    try:
      path.write_text(template.render(context, partial=self._partials.get))
    except TemplateError as e:
      raise DFACCTOError(str(e))


