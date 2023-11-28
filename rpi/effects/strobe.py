from ...interface import LightConfig, DynamicLightConfig
from ..solid_color import SolidColor


class Strobe(DynamicLightConfig):
    """
    Add a strobe effect to a given ``LightConfig``.
    """
    _strobe_count = 0

    def __init__(self, config: LightConfig = SolidColor('#FFFFFF'),
                 strobe_speed: int = 2, **kwargs):
        """
        Initialize a new Stobe configuration.

        Please note that ``strobe_speed``
        uses different units than the ``speed`` parameter of
        ``DynamicLightConfig``. ``strobe_speed`` is defined as the number of
        "on" frames to push before turning the lights off for a frame. For
        example, say ``config`` is a light config that switches between red
        and green every frame and ``strobe_speed`` is set to 2. The animation
        would go like so:

        Frame 1: red
        Frame 2: green
        Frame 3: off (would be red)
        Frame 4: green
        Frame 5: red
        Frame 6: off (would be green)

        At a high level, the important thing to not is that a HIGHER
        ``strobe_speed`` value means a SLOWER strobe. A value of 1 means that
        every other frame is turned off, which is the maximum strobe speed.

        :param config: the light config to add a strobe effect to
        :param strobe_speed: the speed to strobe at (1 is fastest)
        """
        if isinstance(config, DynamicLightConfig):
            super().__init__(config.speed, config.num_leds, **kwargs)
        else:
            # if there is no speed to reference, use default value
            super().__init__(10, config.num_leds, **kwargs)

        self._config = config
        self.strobe_speed = strobe_speed

    def __next__(self):
        self._strobe_count = self._strobe_count + 1 % self.strobe_speed
        pixels = next(self._config)

        if self._strobe_count == 0:
            return [(0, 0, 0)] * self.num_leds
        else:
            return pixels
