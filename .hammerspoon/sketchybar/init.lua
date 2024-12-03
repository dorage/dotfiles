print("here")

local manager = require("sketchybar.manager")

manager.config({ sec = 5 })

manager.add_widget(require("sketchybar.widgets.active-app"))
manager.add_widget(require("sketchybar.widgets.battery"))
manager.add_widget(require("sketchybar.widgets.memory"))
manager.add_widget(require("sketchybar.widgets.storage"))
manager.add_widget(require("sketchybar.widgets.wifi"))
