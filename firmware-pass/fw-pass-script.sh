#! /usr/bin/expect
spawn sudo firmwarepasswd -setpasswd
expect {
     "Enter new password:" {
          send "FirstPassword\r"
          exp_continue
     }
     "Re-enter new password:" {
          send "SecondPassword\r"
          exp_continue
     }
}