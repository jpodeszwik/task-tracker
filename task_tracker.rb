require 'Qt4'

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
        @actions = ["Activity1", "Activity2", "Activity3", "Rest"]
        @currentAction = @actions[-1]
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
            act = self.addAction action
            act.connect(act, SIGNAL('triggered()')) do
                puts action + ' ' + Time.now.inspect
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
