require 'fileutils'
require 'pathname'

game_path = Pathname.new("games/#{Pathname.new('.').realpath.basename}/game")
FileUtils.cd '../../current'

guard :shell do
  watch(%r{\.\./#{game_path}/(.*.rb)}) { |m|
    test_path = m[1].include?('tests/') ? Pathname.new(m[1]) : Pathname.new('tests') / m[1]
    next unless (game_path / test_path).exist?

    `./dragonruby #{game_path} --test #{test_path}`
  }
end
