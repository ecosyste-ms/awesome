require 'bundler/setup'
require 'language_list'
Bundler::GemHelper.install_tasks

require 'rake/testtask'
Rake::TestTask.new do |t|
  t.test_files = FileList['test/language_list_test.rb']
  t.verbose = true
end

task :dump do
  path = File.expand_path(File.join('..', 'data', 'languages.yml'), __FILE__)
  data = YAML.load_file(path)
  entries = data.map { |entry| LanguageList::LanguageInfo.new(entry) }
  output_path = File.expand_path(File.join('..', 'data', 'dump'), __FILE__)
  File.write(output_path, Marshal.dump(entries))
end

task :default => :test
