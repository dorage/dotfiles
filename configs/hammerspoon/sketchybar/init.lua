local manager = require("sketchybar.manager")

manager.add_widget(require("sketchybar.widgets.active-app"), { only_init = true })
manager.add_widget(require("sketchybar.widgets.wifi"), { only_init = true })
