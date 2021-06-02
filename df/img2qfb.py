import argparse
import os 

from enum import Enum
from typing import Optional, Dict

from PIL import Image


class Colors(Enum):

    # Color      R    G    B
    RED     = (255,   0,   0)
    YELLOW  = (255, 255,   0)
    WHITE   = (255, 255, 255)
    BLUE    = (  0,   0, 255)
    BLACK   = (  0,   0,   0)
    GREEN   = (  0, 255,   0)

    @staticmethod
    def get(pixel: tuple):
        for color in Colors:
            if pixel == color.value:
                return color
        return None

    def __str__(self):
        return str(self.value)


class QuickFortCodes(Enum):

    # Special Codes
    EMPTY          = ' '
    START          = 'START'
    GO_DOWN        = '#> '
    GO_UP          = '#< '

    # Designation / Dig Cods
    CHANNEL        = 'h'
    DOWN_STAIR     = 'j'
    ENGRAVE_STONE  = 'e'
    MINE           = 'd'
    SMOOTH_STONE   = 's'
    UP_DOWN_STAIRS = 'i'
    UP_STAIRS      = 'u'
    UP_RAMP        = 'r'

    def __str__(self):
        return self.value


DEFAULT_COLOR_MAP = {
    Colors.WHITE  : QuickFortCodes.EMPTY,
    Colors.RED    : QuickFortCodes.MINE,
    Colors.BLUE   : QuickFortCodes.UP_DOWN_STAIRS,
    Colors.BLACK  : QuickFortCodes.UP_STAIRS,
    Colors.YELLOW : QuickFortCodes.START,
    Colors.GREEN  : QuickFortCodes.CHANNEL,
}


class QuickFortMap:

    def __init__(self, width: int, height: int):
        if width <= 0:
            raise ValueError('Width must be greater or equal to 0')
        if height <= 0:
            raise ValueError('Height must be greater or equal to 0')

        self._height = height
        self._width = width
        self._start_x = 0
        self._start_y = 0
        self._code_map = []
        for x in range(0, self._width):
            col = []
            for y in range(0, self._height):
                col.append(QuickFortCodes.EMPTY)
            self._code_map.append(col)

    @property
    def start_x(self) -> int:
        return self._start_x

    @start_x.setter
    def start_x(self, x: int):
        if not isinstance(x, int) or x < 0 or x >= self._width:
            raise ValueError(f'Starting x position must be an integer >= 0 and < {self._width}, but got {x} ({type(x)})')
        self._start_x = x

    @property
    def start_y(self) -> int:
        return self._start_y

    @start_y.setter
    def start_y(self, y: int):
        if not isinstance(y, int) or y < 0 or y >= self._height:
            raise ValueError(f'Starting y position must be an integer >= 0 and < {self._height}, but got {y} ({type(y)})')
        self._start_y = y

    def _index_error(self, location: tuple) -> Optional[Exception]:
        if not isinstance(location, tuple) or len(location) != 2:
            return IndexError('Location must be a tuple of two integers')
        if not isinstance(location[0], int) or not isinstance(location[1], int):
            return IndexError('Location must be a tuple of two integers')
        if location[0] < 0 or location[0] > self._width:
            return IndexError(f'The x coordinate must be between 0 and {self._width}')
        if location[1] < 0 or location[1] > self._height:
            return IndexError(f'The y coordinate must be between 0 and {self._height}')
        return None

    def __getitem__(self, location: tuple):
        error = self._index_error(location)
        if error:
            raise error
        x, y = location
        return self._code_map[x][y]

    def __setitem__(self, location: tuple, value: QuickFortCodes):
        error = self._index_error(location)
        if error:
            raise error
        x, y = location
        if not isinstance(value, QuickFortCodes):
            raise ValueError('Value must be of type QuickFortCodes enumeration')
        self._code_map[x][y] = value


    def get_blueprint_csv(self, z_repeat: int = 0) -> str:
        if not isinstance(z_repeat, int):
            raise ValueError('The parameter z_repeat must be an integer')
        z_code = QuickFortCodes.GO_DOWN if z_repeat < 0 else QuickFortCodes.GO_UP
        # Quick Fort is 1 based indexing
        rows = [f'#dig start({self.start_x + 1};{self.start_y + 1})']
        for z in range(0,  abs(z_repeat) + 1):
            for y in range(0, self._height):
                row = []
                for x in range(0, self._width):
                    row.append(self[x,y].value)
                rows.append(','.join(row))
            if z_repeat:
                rows.append(z_code.value)
        return '\n'.join(rows)


class ImageMapper:

    def __init__(self, file_path: str, color_map: Dict[Colors, QuickFortCodes] = None, strict: bool = False):
        self._color_map = color_map if color_map else DEFAULT_COLOR_MAP
        self._file_path = os.path.abspath(os.path.expanduser(file_path))
        self._strict = strict
        with Image.open(self._file_path) as img:
            if img.format != 'PNG':
                raise NotImplementedError(f'The format {img.format} not supported.')
            self._width, self._height = img.size
            self._pixels = img.load()

    def _get_qf_code_at(self, x: int, y: int) -> QuickFortCodes:
        raw_color = tuple(self._pixels[x,y][0:3])
        color = Colors.get(raw_color)
        if self._strict and color is None:
            raise ValueError(f'Strict mapping enabled and no code could be mapped for {raw_color} (R,G,B)')
        return self._color_map.get(color, QuickFortCodes.EMPTY)

    def get_qf_map(self) -> QuickFortMap:
        qf_map = QuickFortMap(self._width, self._height)
        for y in range(0, self._height):
            for x in range(0, self._width):
                code = self._get_qf_code_at(x, y)
                if code == QuickFortCodes.START:
                    code = QuickFortCodes.EMPTY
                    qf_map.start_x = x
                    qf_map.start_y = y
                qf_map[x,y] = code
        return qf_map


def arguments():
    parser = argparse.ArgumentParser(description='Convert a PNG to QuickFort CSV.')
    parser.add_argument(
        'img_path',
        type=str,
        help='file path to png to convert',
    )
    parser.add_argument(
        '-s', '--strict',
        help='fail the script if a color doe not map to a quick fort code',
        action='store_true'
    )
    parser.add_argument(
        '-z', '--z-repeat',
        type=int,
        help='number of z levels to repeat; negative means down, postive means up',
        default=0
    )
    return parser.parse_args()


def main():
    args = arguments()
    mapper = ImageMapper(args.img_path, strict=args.strict)
    qf_map = mapper.get_qf_map()
    print(qf_map.get_blueprint_csv(args.z_repeat))


if __name__ == '__main__':
    main()
