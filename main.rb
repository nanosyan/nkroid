#!/usr/bin/ruby
# coding: utf-8
$dir = File.expand_path(".")
print "init..."
$init_thread = Thread.new{loop{sleep 0.4;$stderr.print "."}}

#ねくろいどはご覧のスポンサーでお送りいたします
require "twitter"
require "pg"
require "yaml"
require "logger"
require "./accounts"
$init_thread.kill;puts

#変数定義
#桐間紗路ちゃんのおパンツドリップコーヒー
$console = Logger.new($stdout)
$console.progname = "nkroid"
$console.datetime_format = "%Y-%m-%d %H:%M:%S"
$console.formatter = proc{|severity, datetime, progname, message|
	"[#{severity} #{datetime}] #{message}\n"
}
$accounts = AccountManager.new
$keys = YAML.load_file($dir+"/data/keys.yml")
$rest = Twitter::REST::Client.new($keys[0]);$accounts<<$rest #メインアカウント
$keys[1..-2].each{|key|$accounts<<Twitter::REST::Client.new(key)} #規制用アカウント
$stream = Twitter::Streaming::Client.new($keys[0])
$db = PG::connect(YAML.load_file($dir+"/data/dbconfig.yml")["connection"])
$threads = []

#外部読み込み処理開始
cores = Dir.glob($dir+"/system/*.rb").sort
cores.each do |core|
	core =~ /system\/(.+\.rb)$/
	$console.info "Load #{$1}"
	eval(File.read(core)) end
plugins = Dir.glob($dir+"/plugins/*.rb").sort
plugins.each do |plugin|
	plugin =~ /plugins\/(.+\.rb)$/
	$console.info "Load #{$1}"
	eval(File.read(plugin)) end

$markov = Markov.new

def main
	$stream.user(:replies => "all") do |obj|
		$threads << Thread.new{extract_obj obj}
		if $threads.length > 9
			$threads[0].kill
			$threads.slice! 0
		end
	end
rescue => e
	$console.error e
	main
end

main()