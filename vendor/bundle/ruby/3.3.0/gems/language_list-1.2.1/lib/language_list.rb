require 'yaml'

module LanguageList
  class LanguageInfo
    attr_reader :name, :iso_639_3, :iso_639_1, :iso_639_2b, :iso_639_2t, :type

    def initialize(options)
      @name = options[:name]
      @common_name = options[:common_name]
      @iso_639_3 = options[:iso_639_3]
      @iso_639_1 = options[:iso_639_1]
      @iso_639_2b = options[:iso_639_2b]
      @iso_639_2t = options[:iso_639_2t]
      @common = options[:common]
      @type = options[:type]
    end

    def common_name
      @common_name || @name
    end

    def common?
      @common
    end

    def <=>(other)
      self.name <=> other.name
    end

    def iso_639_1?
      !@iso_639_1.nil?
    end

    [:ancient, :constructed, :extinct, :historical, :living, :special].each do |type|
      define_method("#{type.to_s}?") do
        @type == type
      end
    end

    def to_s
      "#{@iso_639_3}#{" (#{@iso_639_1})" if @iso_639_1} - #{@name}"
    end

    def self.find_by_iso_639_1(code)
      LanguageList::BY_ISO_639_1[code]
    end

    def self.find_by_iso_639_3(code)
      LanguageList::BY_ISO_639_3[code]
    end

    def self.find_by_iso_639_2b(code)
      LanguageList::BY_ISO_639_2B[code]
    end

    def self.find_by_iso_639_2t(code)
      LanguageList::BY_ISO_639_2T[code]
    end

    def self.find_by_name(name)
      return if name.nil?
      
      LanguageList::BY_NAME[name.downcase]
    end

    def self.find(code)
      return if code.nil?
      
      code = code.downcase
      find_by_iso_639_1(code) ||
        find_by_iso_639_3(code) ||
        find_by_iso_639_2b(code) ||
        find_by_iso_639_2t(code) ||
        find_by_name(code)
    end
  end

  ALL_LANGUAGES = begin
     Marshal.load(File.read(File.expand_path('../../data/dump', __FILE__)))
  rescue => e
    warn "Reverting to hash load: #{e.message}"
    yaml_data = YAML.load_file(File.expand_path(File.join(File.dirname(__FILE__),'..', 'data', 'languages.yml')))
    yaml_data.map{|e| LanguageInfo.new(e) }
  end.freeze
  ISO_639_1 = ALL_LANGUAGES.select(&:iso_639_1?).freeze
  LIVING_LANGUAGES = ALL_LANGUAGES.select(&:living?).freeze
  COMMON_LANGUAGES = ALL_LANGUAGES.select(&:common?).freeze

  BY_NAME      = {}
  BY_ISO_639_1 = {}
  BY_ISO_639_3 = {}
  BY_ISO_639_2B = {}
  BY_ISO_639_2T = {}
  ALL_LANGUAGES.each do |lang|
    BY_NAME[lang.name.downcase] = lang
    BY_ISO_639_1[lang.iso_639_1] = lang if lang.iso_639_1
    BY_ISO_639_3[lang.iso_639_3] = lang if lang.iso_639_3
    BY_ISO_639_2B[lang.iso_639_2b] = lang if lang.iso_639_2b
    BY_ISO_639_2T[lang.iso_639_2t] = lang if lang.iso_639_2t
  end
  BY_NAME.freeze
  BY_ISO_639_1.freeze
  BY_ISO_639_3.freeze
  BY_ISO_639_2B.freeze
  BY_ISO_639_2T.freeze
end
