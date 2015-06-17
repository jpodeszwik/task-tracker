require 'Qt4'
require './db.rb'

class InputTaskWindow < Qt::Widget
    signals 'new_task(QString)'

    def initialize
        super
        
        setWindowTitle "Input task"

        edit = Qt::LineEdit.new self
        button = Qt::PushButton.new 'Add', self
        self.connect(button, SIGNAL('clicked()')) do
            emit new_task edit.text
            self.hide
        end
    
        button.move(0, 30)

        show
    end
end

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

    def reload
        @actions = Activity.all
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
    slots 'new_task(QString)'

    def initialize
        super
        @actions = Actions.new
        @actions.each do |action|
            self.setActionsBehaviour action
        end
        
        self.addNewActivityAction

        self.addExitAction
    end

    def setActionsBehaviour action
        act = self.addAction action.name
        act.connect(act, SIGNAL('triggered()')) do
            puts 'Current: ' + @actions.getCurrent.name
            @actions.setCurrent action
            puts 'New: ' + action.name
        end
    end

    def newActionWindow
        InputTaskWindow.new
    end

    def addAction(text)
        action = Action.new text, self
        super(action)
        action
    end

    def new_task(name)
        activity = Activity.create(:name => name)
        @actions.reload
        self.setActionsBehaviour activity
        puts 'New task: ' + name
    end

    def addNewActivityAction
        activityAction = self.addAction 'New Activity'
        activityAction.connect(activityAction, SIGNAL('triggered()')) do
            actionWindow = self.newActionWindow
            actionWindow.connect(actionWindow, SIGNAL('new_task(QString)'), self, SLOT("new_task(QString)"))
        end
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
