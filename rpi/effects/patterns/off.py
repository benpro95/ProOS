from .solid_color import SolidColor


class Off(SolidColor):
    """
    Turn the LEDs off.
    """

    def __init__(self, **kwargs):
        super().__init__('#000000', **kwargs)  # put black pixels
