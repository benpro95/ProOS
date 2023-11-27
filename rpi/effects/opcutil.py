"""
Module for Open Pixel Control utilities. This module provides color definitions
and list manipulation functions. The list manipulation functions are designed
to be used with lists of ColorData (for pushing colors to LEDs), but they can
be used with any kinds of lists.
"""

import re
import math

from typing import Any, Tuple, List

__all__ = [
    'ColorData',
    'ColorHex',
    'ColorList',
    'is_color',
    'is_color_list',
    'get_color',
    'shift',
    'even_spread',
    'spread',
    'rotate_left',
    'rotate_right'
]


ColorData = Tuple[float, float, float]  # 3-tuple representing actual RGB value
ColorHex = str  # ``color`` must be "#RRGGBB" format
ColorList = List[ColorHex]  # ``color_list`` must be non-empty list of ColorHex


def is_color(v: Any) -> bool:
    """
    Determine whether ``v`` is a valid ``ColorHex``.
    """
    return isinstance(v, str) and bool(re.match(r'^#[A-Fa-f0-9]{6}$', v))


def is_color_list(v: Any) -> bool:
    """
    Determine whether ``v`` is a valid ``ColorList``.
    """
    return isinstance(v, list) and len(v) > 0 and all([is_color(c) for c in v])


def get_color(hex_str: ColorHex) -> ColorData:
    """
    Calculate a 3-tuple representing the color in the given hex.

    :param hex_str: the desired color in the format #RRGGBB.
    :return: a 3-tuple of RGB values ``hex_str`` represents
    :raises ValueError: if ``hex_str`` is improperly formatted
    """
    if not is_color(hex_str):
        hex_repr = f"'{hex_str}'" if type(hex_str) is str else str(hex_str)
        raise ValueError("Please provide a color in the format '#RRGGBB'. "
                         f"Received {hex_repr}.")

    def hexfloat(h: str) -> float:
        return float(int(h, 16))

    red = hexfloat(hex_str[1:3])
    blue = hexfloat(hex_str[3:5])
    green = hexfloat(hex_str[5:7])

    return red, blue, green


def shift(current: ColorData, goal: ColorData, p: float) -> ColorData:
    """
    Shift a color towards another.

    :param current: a 3-tuple representing the starting color
    :param goal: a 3-tuple representing the color to shift towards
    :param p: a value indicating how far to shift (0 => no shift, 1 => ``goal``)
    :return: the shifted color
    """
    new_vals = [c + ((g - c) * p) for c, g in zip(current, goal)]
    # explicitly give the first 3 values so it doesn't complain about being
    # Tuple[float, ...] rather than Tuple[float, float, float]
    return new_vals[0], new_vals[1], new_vals[2]


def even_spread(vals: List, n: int) -> List:
    """
    Spread out the values across a larger list in order as evenly as possible.

    Example:
    >>> even_spread([1, 2, 3], 8) == [1, 1, 1, 2, 2, 2, 3, 3]

    :param vals: a list of values to spread
    :param n: the length of the list to create from the given values
    :return: a list consisting of ``colors`` spread across ``num_leds`` indices
    :raises ValueError: if ``colors`` is empty or ``num_leds`` is negative
    """
    if len(vals) < 1:
        raise ValueError('no values provided')
    if n < 0:
        raise ValueError('list length cannot be negative')

    new_vals = []
    length_per_val = math.floor(n / len(vals))
    remainder = n % len(vals)
    extra_vals = vals[:remainder]

    for val in vals:
        new_vals += [val] * length_per_val
        if val in extra_vals:
            new_vals.append(val)

    return new_vals


def spread(vals: List, seq_length: int, list_length: int):
    """
    Spread out values across a certain number of indices using the specified
    number of times to repeat each value, repeating if the end of ``vals`` is
    reached.

    Examples:
    >>> spread([1, 2, 2, 3], 2, 7) == [1, 1, 2, 2, 2, 2, 3]

    >>> spread([4, 5], 3, 8) == [4, 4, 4, 5, 5, 5, 4, 4]

    :param vals: the values to spread
    :param seq_length: the length of each value sequence
    :param list_length: the length of the list to create from the given colors
    :return: a list consisting of sequences of values in ``vals`` of length
        ``r`` each
    :raises ValueError: if ``vals`` is empty or either ``n`` or
        ``r`` is negative
    """
    if len(vals) < 1:
        raise ValueError('no values provided')
    if list_length < 0:
        raise ValueError('list length cannot be negative')
    if seq_length < 0:
        raise ValueError('sequence length cannot be negative')

    new_vals = []
    idx = 0
    remaining = list_length
    while remaining > 0:
        new_vals += [vals[idx]] * min(seq_length, remaining)
        idx = (idx + 1) % len(vals)
        remaining -= seq_length

    return new_vals


def rotate_left(l: List, n: int):
    """
    Generate a version of the given list rotated left.

    :param l: the list to rotate
    :param n: how many spaces to rotate the list
    :return: the rotated list
    """
    n %= len(l)
    return l[n:] + l[:n]


def rotate_right(l: List, n: int):
    """
    Generate a version of the given list rotated right

    :param l: the list to rotate
    :param n: how many spaces to rotate the list
    :return: the rotated list
    """
    n %= len(l)
    return l[-n:] + l[:-n]
