require 'rubygems'
require 'Nokogiri'
require 'Mechanize'

class LOLKingCrawler
  attr_reader :items
  DOMAIN = "http://www.lolking.net"

  def initialize
    @agent = Mechanize.new
  end

  def crawl
    print "Starting crawling service.\n"

    item_threads = item_links.map do |link|
      Thread.new(link) { |link| item_info(link) }
    end

    champion_threads = champion_links do |link|
      Thread.new(link) { |link| item_info(link) }
    end

    @items = item_threads.map(&:value)
    @champions = champion_threads.map(&:value)
    print "OK\nCrawl Service Complete.\n"
  end

  def items
    @items || crawl
  end

  def champions
    @champions || crawl
  end

  private

  def item_links
    url = 'items'
    index_page = @agent.get("#{DOMAIN}/#{url}")

    print "Gathering item pages.\n"
    @item_links = index_page.links_with href: /items\/(?<id>\d)/
  end

  def champion_links
    url = 'champions'
    index_page = @agent.get("#{DOMAIN}/#{url}")
    print "Gathering champion pages.\n"
    @champion_links
    page.links_with(href: /champions\/(?<slug>\w+\Z)/).each do |link|
      @champion_links[:"#{slug}"] = link
    end
  end

  def champion_info(link)
    page = link.click
    abilities = []
    page.search('td.ability h3').each { |ab| abilities += ab.text.strip }
    abilities.each do |ability|
      champion_name = link.href.slice(/\w\/champions\//).capitalize
      Ability.new :name ability, champion_name: link
    end
    mobafire_url = 'http://www.mobafire.com/league-of-legends/champions'
  end

  def item_info(link)
    print "Visiting #{DOMAIN}#{link.href}\n"
    page = link.click
    name = page.search('div.lol-tt-name').text.strip
    attributes  = String.new
    description = String.new
    page.search('div.lol-tt-desc').children.search('span').each {|span| attributes.concat "#{span.text}\n"}
    description = page.search('div.lol-tt-desc').text.strip
      .gsub(%r{(?<d>[a-z])\+}, "\\k<d>\n+")
      .gsub(%r{(?<d>[a-z])(?<d2>[A-Z])}, "\\k<d>\n\\k<d2>")
      .gsub(".UNIQUE", ".\nUNIQUE")
      .gsub /\.\(Unique/, ".\n(Unique"
    Item.new name: name, attributes: attributes, url: link.href, description: description
  end
end

class Item
  attr_accessor :id, :url, :description, :name, :attributes
  def initialize(attributes)
    attributes.each do |key,value|
      instance_variable_set("@#{key}", value) unless value.nil?
    end
  end
end

class Ability
  attr_accessor :champion_name
  def initialize(attributes)
    attributes.each do |key,value|
      instance_variable_set("@#{key}", value) unless value.nil?
    end
  end
end

class Champion
  attr_accessor :id, :url, :lore, :name, :base_stats, :abilities
  def initialize(attributes)
    attributes.each do |key,value|
      instance_variable_set("@#{key}", value) unless value.nil?
    end
  end
end

llkc = LOLKingCrawler.new
llkc.crawl
llkc.items.each {|item| print "#{item.name}:\new\n#{item.description}\n\n" }