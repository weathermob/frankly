require 'frankly/localize'

module Frankly
  
  class Simulator
    
    def quit
        %x{osascript<<APPLESCRIPT-
          application "iPhone Simulator" quit
        APPLESCRIPT}
    end

    def reset_data
      %x{osascript<<APPLESCRIPT
    activate application "iPhone Simulator"
    tell application "System Events"
      click menu item 5 of menu 1 of menu bar item 2 of menu bar 1 of process "#{Localize.t(:iphone_simulator)}"
      delay 0.5
      click button 2 of window 1 of process "#{Localize.t(:iphone_simulator)}"
    end tell
      APPLESCRIPT} 
    end

      #Note this needs to have "Enable access for assistive devices"
      #chcked in the Universal Access system preferences
      def menu_press( menu_label )
        %x{osascript<<APPLESCRIPT
    activate application "iPhone Simulator"
    tell application "System Events"
    	click menu item "#{menu_label}" of menu "#{Localize.t(:hardware)}" of menu bar of process "#{Localize.t(:iphone_simulator)}"
    end tell
      APPLESCRIPT}  
      end

      def press_home
        menu_press Localize.t(:home)
      end

      def rotate_left
        menu_press Localize.t(:rotate_left)
      end

      def rotate_right
        menu_press Localize.t(:rotate_right)
      end

      def shake
        menu_press Localize.t(:shake_gesture)
      end

      def simulate_memory_warning
        menu_press Localize.t(:simulate_memory_warning)
      end

      def toggle_call_status_bar
        menu_press Localize.t(:toggle_call_status_bar)
      end

      def simulate_hardware_keyboard
        menu_press Localize.t(:simulate_hardware_keyboard)
      end
    end
  end