import abc
import time

from typing import List, Iterator
from . import opc
from .opcutil import ColorData, ColorHex, is_color, is_color_list

__all__ = ['LightConfig', 'DynamicLightConfig', 'StaticLightConfig']

# IDEA
# Lighting configurations are iterators that generate the next list of pixels
# to put onto an LED strip. The run method steps through the iterator and does
# the work of pushing the generated list to the Fadecandy client.


# TODO: Add ability to control brightness
class LightConfig(abc.ABC):
    """
    Abstract base class for an LED lighting configuration.
    """
    client: opc.Client

    def __init__(self, num_leds: int = 512, **kwargs):
        """
        Initialize a new LightConfig.

        :param num_leds: the number of LEDs
        """
        self.num_leds: int = num_leds

    def __iter__(self) -> Iterator:
        """
        Define any LightConfig to be iterable.
        """
        return self

    @abc.abstractmethod
    def __next__(self) -> List[ColorData]:
        """
        Get the next list of colors to push to the Fadecandy client.
        """

    @abc.abstractmethod
    def run(self, host: str = 'localhost', port: int = 7890) -> None:
        """
        Run this lighting configuration.

        :param host: hostname or IP address of Fadecandy server
        :param port: port that the Fadecandy server is running on
        """
        self.client = opc.Client(f'{host}:{port}')

    @staticmethod
    def factory(pattern: str, strobe: bool = False, **kwargs) -> 'LightConfig':
        """
        Generate a ``LightConfig`` based on keywaord arguments. Different
        patterns differ in required keyword arguments.

        :param pattern: the name of the desired lighting configuration
        :param strobe: whether to add a strobe effect
        :param kwargs: keyword arguments to pass to LightConfig constructor
        :return: an instance of the class associated with ``pattern``
        :raises ValueError: if ``pattern`` is not associated with any patterns
            or the required arguments for the specified config are not provided
        """
        # importing patterns at the top of file causes circular import issues
        from . import patterns

        try:
            light = getattr(patterns, pattern)(**kwargs)
        except AttributeError:
            raise ValueError(f'{pattern!r} is not associated with any lighting '
                             f'configurations')

        if strobe:
            light = patterns.modifiers.Strobe(light)

        return light

    @staticmethod
    def validate_color(color: ColorHex) -> None:
        """
        Ensure that a value passed as the ``color`` parameter is valid. This
        means it is a string of the format "#RRGGBB". If the given value
        is invalid, an exception is raised.

        This method should be called in the contructor of ``LightConfig``
        subclasses that take a ``color`` parameter.

        :param color: the ``color`` to validate
        :raises TypeError: if ``color`` is not valid
        """
        if not is_color(color):
            raise TypeError('color must be in format "#RRGGBB"')

    @staticmethod
    def validate_color_list(color_list: List[ColorHex]) -> None:
        """
        Ensure that a value passed as the ``color_list`` parameter is valid.
        This means it is a list of strings in the format "#RRGGBB" with a length
        of at least one. In other words, it is a non-empty ``list[ColorHex]``.
        If the given value is invalid, an exception is raised.

        This method should be called in the contructor of ``LightConfig``
        subclasses that take a ``color_list`` parameter.

        :param color_list: the ``color_list`` to validate
        :raises TypeError: if ``color_list`` is not valid
        """
        if not is_color_list(color_list):
            raise TypeError('color_list must be a non-empty list of strings '
                            'in format "#RRGGBB')


class StaticLightConfig(LightConfig, abc.ABC):
    """
    A lighting configuration that displays an unmoving pattern.
    """

    def __next__(self):
        return self.pattern()

    def run(self, host: str = 'localhost', port: int = 7890) -> None:
        super().run(host, port)  # initialize client
        black = [(0, 0, 0)] * self.num_leds
        pattern = self.pattern()

        # turn off LEDs
        self.client.put_pixels(black)
        self.client.put_pixels(black)

        # fade in to pattern
        time.sleep(0.5)
        self.client.put_pixels(pattern)

    @abc.abstractmethod
    def pattern(self) -> List[ColorData]:
        """
        Define the pattern this lighting configuration should display.
        :return: a list of RGB values to display
        """


class DynamicLightConfig(LightConfig, abc.ABC):
    """
    A lighting configuration that displays a moving pattern.
    """
    speed: int

    def __init__(self, speed: int = None, **kwargs):
        """
        Initialize a new DynamicLightConfig.

        :param speed: the speed at which the lights change (updates per second)
        """
        super().__init__(**kwargs)
        if speed:
            self.speed = speed

    def run(self, host: str = 'localhost', port: int = 7890) -> None:
        super().run(host, port)  # initialize client
        while True:
            pixels = next(self)
            self.client.put_pixels(pixels)
            time.sleep(1 / self.speed)
