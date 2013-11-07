Facter.add(:is_puppetmaster) do
  confine :kernel => "Linux"
  setcode do
    if File.exist? "/etc/default/puppetmaster"
      "true"
    else
      "false"
    end
  end
end
