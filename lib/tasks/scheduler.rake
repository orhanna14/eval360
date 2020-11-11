desc "Automated email reminders"
task :send_reminders => :environment do
  if Date.current.tuesday?
    Training.send_self_eval_reminders
    Training.send_add_peers_reminders
    Training.send_remind_peers_reminders
  end
end
