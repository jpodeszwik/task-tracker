require 'Qt4'
require './db.rb'

class IconSet
    def initialize
        @imgs = [Qt::Icon.new('1.png'), Qt::Icon.new('2.png'), Qt::Icon.new('3.png')] 
    end

    def nextIcon
        @imgs = @imgs.rotate
        @imgs[0]
    end
end

class Action < Qt::Action
    def initialize(text, parent)
        super(text, parent)
    end
end

class Actions
    def initialize
        @actions = Activity.all
        @currentAction = @actions[-1]
        @currentTimes = ActivityTime.create(:activity_id => @currentAction.id, :start => Time.now, :stop => nil)
    end

    def setCurrent(actionToSet)
        self.stopCurrent
        @actions.each do |action|
            if actionToSet == action
                @currentAction = action
                self.startCurrent
            end
        end
    end

    def stopCurrent
        @currentTimes.stop = Time.now
        @currentTimes.save
    end

    def startCurrent
        @currentTimes = ActivityTime.create(:activity_id => @currentAction.id, :start => Time.now, :stop => nil)
    end

    def getCurrent
        @currentAction
    end

    def each
        @actions.each do |action|
            yield action
        end
    end
end

class TrayMenu < Qt::Menu
    def initialize
        super
        @actions = Actions.new
        @actions.each do |action|
            act = self.addAction action.name
            act.connect(act, SIGNAL('triggered()')) do
                puts 'Current: ' + @actions.getCurrent.name
                @actions.setCurrent action
                puts 'New: ' + action.name
            end
        end
        self.addExitAction
    end

    def addAction(text)
        action = Action.new text, self
        super(action)
        action
    end

    def addExitAction
        exitAction = self.addAction 'Exit'
        exitAction.connect(exitAction, SIGNAL('triggered()'), Qt::Application.instance, SLOT("quit()"))
    end
end

class TrayIcon 
    def initialize
        @si  = Qt::SystemTrayIcon.new
        @menu = TrayMenu.new
        @icons = IconSet.new
        @si.icon = @icons.nextIcon
        @si.setContextMenu @menu

        self.addIconActions

        @si.show

    end

    def addIconActions
        @si.connect(SIGNAL('activated(QSystemTrayIcon::ActivationReason)')) do |reason|
            case reason
                when Qt::SystemTrayIcon::Trigger
                    @si.icon = @icons.nextIcon
            end
        end
    end
    
end

class Application
    def initialize 
        @app = Qt::Application.new(ARGV)
        @trayIcon = TrayIcon.new
    end

    def run
        @app.exec
    end
end

begin
    Application.new.run
rescue Interrupt => e
    puts 'Interrupted'
end
