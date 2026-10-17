# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

require 'loog'
require 'nokogiri'
require 'qbash'
require_relative '../test__helper'

class TestAwards < Minitest::Test
  def test_fn_payables
    xml = xslt(
      "<xsl:copy-of select=\"z:payables('dude')\"/>",
      "
      <fb>
        <f>
          <what>reconciliation</what>
          <when>#{(Time.now - (60 * 60)).utc.iso8601}</when>
          <since>#{(Time.now - (50 * 60 * 60)).utc.iso8601}</since>
          <who_name>dude</who_name>
          <awarded>100</awarded>
          <payout>70</payout>
          <balance>30</balance>
        </f>
        <f>
          <is_human>1</is_human>
          <when>#{(Time.now - (10 * 60 * 60)).utc.iso8601}</when>
          <who_name>dude</who_name>
          <award>40</award>
        </f>
        <f>
          <is_human>1</is_human>
          <when>#{(Time.now - (10 * 60 * 60)).utc.iso8601}</when>
          <who_name>dude</who_name>
          <award>60</award>
        </f>
        <f>
          <is_human>1</is_human>
          <when>#{Time.now.utc.iso8601}</when>
          <who_name>dude</who_name>
          <award>25</award>
        </f>
      </fb>
      ",
      'today' => Time.now.utc.iso8601
    )
    assert_equal('55', xml.xpath('/td/text()').to_s, xml)
  end

  def test_fn_payables_out_of_window
    xml = xslt(
      "<xsl:copy-of select=\"z:payables('dude')\"/>",
      "
      <fb>
        <f>
          <what>reconciliation</what>
          <when>#{(Time.now - (60 * 60)).utc.iso8601}</when>
          <since>#{(Time.now - (1000 * 60 * 60)).utc.iso8601}</since>
          <who_name>dude</who_name>
          <awarded>0</awarded>
          <payout>20</payout>
          <balance>10</balance>
        </f>
        <f>
          <is_human>1</is_human>
          <when>#{(Time.now - (999 * 60 * 60)).utc.iso8601}</when>
          <who_name>dude</who_name>
          <award>40</award>
        </f>
        <f>
          <is_human>1</is_human>
          <when>#{Time.now.utc.iso8601}</when>
          <who_name>dude</who_name>
          <award>25</award>
        </f>
      </fb>
      ",
      'today' => Time.now.utc.iso8601
    )
    assert_equal('75', xml.xpath('/td/text()').to_s, xml)
  end

  def test_fn_payables_ignores_reconciliations_after_report_date
    xml = xslt(
      "<xsl:copy-of select=\"z:payables('dude')\"/>",
      '
      <fb>
        <f>
          <what>reconciliation</what>
          <when>2024-05-31T00:00:00Z</when>
          <since>2024-05-01T00:00:00Z</since>
          <who_name>dude</who_name>
          <awarded>0</awarded>
          <payout>0</payout>
          <balance>0</balance>
        </f>
        <f>
          <what>reconciliation</what>
          <when>2024-06-03T00:00:00Z</when>
          <since>2024-06-03T00:00:00Z</since>
          <who_name>dude</who_name>
          <awarded>0</awarded>
          <payout>0</payout>
          <balance>99</balance>
        </f>
        <f>
          <is_human>1</is_human>
          <when>2024-06-01T00:00:00Z</when>
          <who_name>dude</who_name>
          <award>10</award>
        </f>
      </fb>
      ',
      'today' => '2024-06-02T00:00:00Z'
    )
    assert_equal('10', xml.xpath('/td/text()').to_s, xml)
  end

  def test_fn_payables_with_few_reconciliations
    xml = xslt(
      "<xsl:copy-of select=\"z:payables('dude')\"/>",
      "
      <fb>
        <f>
          <what>reconciliation</what>
          <when>#{(Time.now - (100 * 60 * 60)).utc.iso8601}</when>
          <since>#{(Time.now - (200 * 60 * 60)).utc.iso8601}</since>
          <who_name>dude</who_name>
          <awarded>400</awarded>
          <payout>230</payout>
          <balance>-120</balance>
        </f>
        <f>
          <what>reconciliation</what>
          <when>#{(Time.now - (60 * 60)).utc.iso8601}</when>
          <since>#{(Time.now - (50 * 60 * 60)).utc.iso8601}</since>
          <who_name>dude</who_name>
          <awarded>100</awarded>
          <payout>70</payout>
          <balance>30</balance>
        </f>
        <f>
          <is_human>1</is_human>
          <when>#{(Time.now - (10 * 60 * 60)).utc.iso8601}</when>
          <who_name>dude</who_name>
          <award>40</award>
        </f>
        <f>
          <is_human>1</is_human>
          <when>#{(Time.now - (10 * 60 * 60)).utc.iso8601}</when>
          <who_name>dude</who_name>
          <award>60</award>
        </f>
        <f>
          <is_human>1</is_human>
          <when>#{Time.now.utc.iso8601}</when>
          <who_name>dude</who_name>
          <award>25</award>
        </f>
      </fb>
      ",
      'today' => Time.now.utc.iso8601
    )
    assert_equal('55', xml.xpath('/td/text()').to_s, xml)
  end

  def test_fn_payables_uses_latest_reconciliation_when_facts_are_out_of_order
    xml = xslt(
      "<xsl:copy-of select=\"z:payables('dude')\"/>",
      "
      <fb>
        <f>
          <what>reconciliation</what>
          <when>
            <v>2024-09-20T00:00:00Z</v>
            <v>2024-09-20T00:00:00Z</v>
          </when>
          <since>2024-09-19T00:00:00Z</since>
          <who_name>dude</who_name>
          <awarded>0</awarded>
          <payout>0</payout>
          <balance>30</balance>
        </f>
        <f>
          <what>reconciliation</what>
          <when>2024-09-10T00:00:00Z</when>
          <since>2024-09-01T00:00:00Z</since>
          <who_name>dude</who_name>
          <awarded>100</awarded>
          <payout>70</payout>
          <balance>0</balance>
        </f>
        <f>
          <is_human>1</is_human>
          <when>2024-09-21T00:00:00Z</when>
          <who_name>dude</who_name>
          <award>25</award>
        </f>
      </fb>
      ",
      'today' => '2024-09-26T04:04:04Z'
    )
    assert_equal('55', xml.xpath('/td/text()').to_s, xml)
  end

  def test_fn_monday
    xml = xslt(
      '<r><xsl:value-of select="z:monday(1)"/></r>',
      '
      <fb>
        <f>
          <what>pmp</what>
          <area>hr</area>
          <days_of_running_balance>7</days_of_running_balance>
        </f>
      </fb>
      ',
      'today' => '2024-09-26T04:04:04Z'
    )
    assert_equal('2024-09-23Z', xml.xpath('/r/text()').to_s, xml)
  end

  def test_fn_in_week
    xml = xslt(
      '<r><xsl:value-of select="z:in-week(xs:dateTime(\'2024-09-20T04:04:04Z\'), 1)"/></r>',
      '
      <fb>
        <f>
          <what>pmp</what>
          <area>hr</area>
          <days_of_running_balance>14</days_of_running_balance>
        </f>
      </fb>
      ',
      'today' => '2024-09-26T04:04:04Z'
    )
    assert_equal('true', xml.xpath('/r/text()').to_s, xml)
  end

  def test_names_the_week_across_new_year
    xml = xslt(
      "<r><xsl:apply-templates select='/' mode='awards'/></r>",
      '
      <fb>
        <f>
          <what>pmp</what>
          <area>hr</area>
          <days_of_running_balance>28</days_of_running_balance>
        </f>
        <f>
          <is_human>1</is_human>
          <who>1</who>
          <who_name>jeff</who_name>
          <award>10</award>
          <when>2026-01-15T00:00:00Z</when>
        </f>
      </fb>
      ',
      'today' => '2026-01-19T00:00:00Z'
    )
    th = xml.xpath('//thead/tr/th[3]').first
    assert_equal('w1', th.text.strip, xml)
    assert_includes(th['title'], 'Week #1 in 2026', xml)
  end

  def test_sorts_award_details_by_instant
    facts = [
      ['utc', '2024-06-01T00:00:00Z'],
      ['positive offset', '2024-06-01T00:30:00+03:00'],
      ['negative offset', '2024-05-31T23:00:00-02:00']
    ].map do |reason, timestamp|
      "
      <f>
        <is_human>1</is_human>
        <who>1</who>
        <who_name>dude</who_name>
        <award>10</award>
        <why>#{reason}</why>
        <when>#{timestamp}</when>
      </f>
      "
    end.join
    xml = xslt(
      "<r><xsl:apply-templates select='/' mode='awards'/></r>",
      "<fb>#{facts}</fb>",
      'today' => '2024-06-02T00:00:00Z'
    )
    assert_equal(
      ['positive offset', 'utc', 'negative offset'],
      xml.xpath('//tr[contains(@class, "p_dude")]/td[2]').map(&:text),
      xml
    )
  end

  def test_sorts_programmers_by_their_total_awards
    facts = [
      ['alpha', '1', '2024-06-01T00:00:00Z'],
      ['alpha', '100', '2024-05-31T00:00:00Z'],
      ['beta', '50', '2024-05-30T00:00:00Z']
    ].map do |name, amount, timestamp|
      "<f><is_human>1</is_human><who>1</who><who_name>#{name}</who_name>" \
        "<award>#{amount}</award><when>#{timestamp}</when></f>"
    end.join
    xml = xslt(
      "<r><xsl:apply-templates select='/' mode='awards'/></r>",
      "<fb>#{facts}</fb>",
      'today' => '2024-06-02T00:00:00Z'
    )
    rows = xml.xpath('//table[@id="awards"]/tbody/tr[not(contains(@class, "sub"))]')
    assert_equal(%w[alpha beta], rows.map { |row| row.at_xpath('./td[2]/span/a').text.delete_prefix('@') })
  end

  def test_fn_in_week_takes_midnight_of_monday
    xml = xslt(
      '<r><xsl:value-of select="z:in-week(xs:dateTime(\'2024-09-23T00:00:00Z\'), 2)"/></r>',
      '
      <fb>
        <f>
          <what>pmp</what>
          <area>hr</area>
          <days_of_running_balance>14</days_of_running_balance>
        </f>
      </fb>
      ',
      'today' => '2024-09-26T04:04:04Z'
    )
    assert_equal('true', xml.xpath('/r/text()').to_s, xml)
  end

  def test_fn_award
    {
      42 => ['darkgreen', '+42'],
      0 => ['lightgray', '&#x2014;'],
      -7 => ['darkred', '-7']
    }.each do |k, v|
      xml = xslt("<xsl:copy-of select='z:award(#{k})'/>", '<fb/>')
      assert_equal(v[0], xml.xpath('/span/@class').to_s, xml)
      assert_equal(v[1], xml.xpath('/span/text()').to_s, xml)
    end
  end

  def test_programmer_rejects_non_github_href
    now = Time.now.utc.iso8601
    xml = xslt(
      "<r><xsl:call-template name=\"programmer\">
        <xsl:with-param name=\"id\" select=\"'x'\"/>
        <xsl:with-param name=\"name\" select=\"'dude'\"/>
      </xsl:call-template></r>",
      "
      <fb>
        <f>
          <is_human>1</is_human>
          <when>#{now}</when>
          <who_name>dude</who_name>
          <award>25</award>
          <why>evil</why>
          <href>javascript:alert(1)</href>
        </f>
      </fb>
      ",
      'today' => now
    )
    assert_includes(xml.xpath('//tr').text, 'evil', xml)
    assert_empty(xml.xpath("//a[starts-with(@href, 'javascript:')]"), xml)
  end

  def test_payables_accept_multi_valued_since
    xml = xslt(
      "<r><xsl:copy-of select=\"z:payables('dude')\"/></r>",
      '
      <fb>
        <f>
          <what>reconciliation</what>
          <when>2026-09-18T10:00:00Z</when>
          <since><v>2026-09-01T00:00:00Z</v><v>2026-09-02T00:00:00Z</v></since>
          <who_name>dude</who_name>
          <awarded>0</awarded>
          <payout>0</payout>
          <balance>0</balance>
        </f>
        <f>
          <is_human>1</is_human>
          <when>2026-09-10T10:00:00Z</when>
          <who_name>dude</who_name>
          <award>25</award>
        </f>
      </fb>
      ',
      'today' => '2026-09-19T04:04:04Z'
    )
    assert_equal('25', xml.xpath('/r/td').text.strip, xml)
  end

  def test_says_one_day_and_one_award_without_a_plural
    xml = xslt(
      "<r><xsl:apply-templates select='/' mode='awards'/></r>",
      '
      <fb>
        <f>
          <what>pmp</what>
          <area>hr</area>
          <days_of_running_balance>1</days_of_running_balance>
        </f>
        <f>
          <is_human>1</is_human>
          <who>1</who>
          <who_name>jeff</who_name>
          <award>10</award>
          <when>2024-06-01T00:00:00Z</when>
        </f>
      </fb>
      ',
      'today' => '2024-07-05T00:00:00Z'
    )
    text = xml.xpath('//p[@class="darkred"]').text
    assert_includes(text, '(1 day before today)', xml)
    assert_includes(text, 'there is 1 award in total', xml)
  end

  def test_says_awards_for_zero_and_award_for_one
    xml = xslt(
      "<r><xsl:apply-templates select='/' mode='awards'/></r>",
      '
      <fb>
        <f>
          <is_human>1</is_human>
          <who>1</who>
          <who_name>alice</who_name>
          <award>20</award>
          <when>2026-10-14T10:00:00Z</when>
        </f>
        <f>
          <what>reconciliation</what>
          <who>2</who>
          <who_name>dave</who_name>
          <when>2026-10-06T00:00:00Z</when>
          <since>2026-08-01T00:00:00Z</since>
          <awarded>100</awarded>
          <balance>130</balance>
          <payout>70</payout>
        </f>
      </fb>
      ',
      'today' => '2026-10-16T12:00:00Z'
    )
    cells = xml.xpath('//tbody/tr/td[2]').map { |td| td.text.gsub(/\s+/, ' ').strip }
    assert_includes(cells, '@alice (1 award)', xml)
    assert_includes(cells, '@dave (0 awards)', xml)
  end

  def test_renders_a_payout_without_since
    xml = xslt(
      "<r><xsl:apply-templates select='/' mode='awards'/></r>",
      '<fb><f><is_human>1</is_human><who>1</who><who_name>jeff</who_name><award>60</award>' \
      '<when>2024-06-03T00:00:00Z</when></f>' \
      '<f><what>reconciliation</what><who>1</who><who_name>jeff</who_name><when>2024-05-31T00:00:00Z</when>' \
      '<awarded>100</awarded><payout>70</payout><balance>30</balance></f>' \
      '<f><what>reconciliation</what><who>1</who><who_name>jeff</who_name><when>2024-06-05T00:00:00Z</when>' \
      '<since>2024-05-31T00:00:00Z</since><awarded>100</awarded><payout>70</payout><balance>30</balance></f></fb>',
      'today' => '2024-06-10T00:00:00Z'
    )
    assert_includes(
      xml.xpath('//span/@title').map(&:to_s),
      "You've accumulated 100 points, a payout of 70 points has been made on 2024-05-31, " \
      'making the amount payable equal to 30',
      xml
    )
  end

  def test_keeps_the_sort_value_where_tablesorter_reads_it
    xml = xslt('<xsl:copy-of select="z:td-award(0)"/>', '<fb/>')
    assert_equal('0', xml.xpath('/td/@data-text').to_s, xml)
  end

  def test_prints_since_dates_without_timezone
    [
      '<fb/>',
      '<fb><f><what>reconciliation</what><when>2024-07-03T00:00:00Z</when><since>2024-06-01T00:00:00Z</since>' \
      '<who>7</who><who_name>dude</who_name><awarded>100</awarded><payout>70</payout><balance>30</balance></f>' \
      '<f><is_human>1</is_human><who>7</who><who_name>dude</who_name><award>40</award>' \
      '<when>2024-07-02T00:00:00Z</when></f></fb>'
    ].each do |fb|
      xml = xslt("<r><xsl:apply-templates select='/' mode='awards'/></r>", fb, 'today' => '2024-07-05T00:00:00Z')
      assert_match(/(No awards since|Since) \d{4}-\d{2}-\d{2}[ (]/, xml.to_s, xml)
      refute_match(/\d{4}-\d{2}-\d{2}Z/, xml.xpath('//text()').text, xml)
    end
  end

  def test_separates_many_reasons
    xml = xslt(
      "<r><xsl:call-template name=\"programmer\">
        <xsl:with-param name=\"id\" select=\"'1'\"/>
        <xsl:with-param name=\"name\" select=\"'jeff'\"/>
      </xsl:call-template></r>",
      '
      <fb>
        <f>
          <is_human>1</is_human>
          <who>1</who>
          <who_name>jeff</who_name>
          <award>10</award>
          <when>2024-10-08T10:00:00Z</when>
          <why><v>first reason</v><v>second reason</v></why>
        </f>
      </fb>
      ',
      'today' => '2024-10-14T12:00:00Z'
    )
    assert_equal(1, xml.xpath('//td[text()="first reason; second reason"]').size, xml)
  end

  def test_gives_a_row_to_a_programmer_owed_points_without_recent_awards
    xml = xslt(
      "<r><xsl:apply-templates select='/' mode='awards'/></r>",
      '
      <fb>
        <f>
          <what>reconciliation</what>
          <when>2024-05-20T00:00:00Z</when>
          <since>2024-04-01T00:00:00Z</since>
          <who>7</who>
          <who_name>dude</who_name>
          <awarded>100</awarded>
          <payout>70</payout>
          <balance>30</balance>
        </f>
        <f>
          <is_human>1</is_human>
          <who>7</who>
          <who_name>dude</who_name>
          <award>100</award>
          <when>2024-05-01T00:00:00Z</when>
        </f>
        <f>
          <is_human>1</is_human>
          <who>7</who>
          <who_name>dude</who_name>
          <award>45</award>
          <when>2024-05-25T00:00:00Z</when>
        </f>
        <f>
          <is_human>1</is_human>
          <who>8</who>
          <who_name>jeff</who_name>
          <award>10</award>
          <when>2024-07-02T00:00:00Z</when>
        </f>
      </fb>
      ',
      'today' => '2024-07-05T00:00:00Z'
    )
    assert_includes(xml.xpath('//tbody/tr/td[last()]').map { |td| td.text.strip }, '75', xml)
  end

  def test_ignores_future_reconciliation_when_giving_a_row_to_a_programmer_owed_points
    xml = xslt(
      "<r><xsl:apply-templates select='/' mode='awards'/></r>",
      '
      <fb>
        <f>
          <what>reconciliation</what>
          <when>2024-05-20T00:00:00Z</when>
          <since>2024-04-01T00:00:00Z</since>
          <who>7</who>
          <who_name>dude</who_name>
          <awarded>100</awarded>
          <payout>70</payout>
          <balance>30</balance>
        </f>
        <f>
          <what>reconciliation</what>
          <when>2024-08-01T00:00:00Z</when>
          <since>2024-07-31T00:00:00Z</since>
          <who>7</who>
          <who_name>dude</who_name>
          <awarded>0</awarded>
          <payout>75</payout>
          <balance>0</balance>
        </f>
        <f>
          <is_human>1</is_human>
          <who>7</who>
          <who_name>dude</who_name>
          <award>100</award>
          <when>2024-05-01T00:00:00Z</when>
        </f>
        <f>
          <is_human>1</is_human>
          <who>7</who>
          <who_name>dude</who_name>
          <award>45</award>
          <when>2024-05-25T00:00:00Z</when>
        </f>
        <f>
          <is_human>1</is_human>
          <who>8</who>
          <who_name>jeff</who_name>
          <award>10</award>
          <when>2024-07-02T00:00:00Z</when>
        </f>
      </fb>
      ',
      'today' => '2024-07-05T00:00:00Z'
    )
    assert_includes(xml.xpath('//tbody/tr/td[last()]').map { |td| td.text.strip }, '75', xml)
    assert_equal(1, xml.xpath("//tbody/tr[contains(., '@dude')]").size, xml)
  end

  def test_gives_no_row_to_a_programmer_with_only_a_future_reconciliation
    xml = xslt(
      "<r><xsl:apply-templates select='/' mode='awards'/></r>",
      '
      <fb>
        <f>
          <what>reconciliation</what>
          <when>2024-08-01T00:00:00Z</when>
          <since>2024-04-01T00:00:00Z</since>
          <who>9</who>
          <who_name>later</who_name>
          <awarded>0</awarded>
          <payout>0</payout>
          <balance>50</balance>
        </f>
        <f>
          <is_human>1</is_human>
          <who>8</who>
          <who_name>jeff</who_name>
          <award>10</award>
          <when>2024-07-02T00:00:00Z</when>
        </f>
      </fb>
      ',
      'today' => '2024-07-05T00:00:00Z'
    )
    assert_empty(xml.xpath("//tbody/tr[contains(., '@later')]"), xml)
    assert_equal(1, xml.xpath("//tbody/tr[contains(., '@jeff')]").size, xml)
  end

  def test_shows_awards_with_unknown_humanity_and_hides_bots
    xml = xslt(
      "<r><xsl:apply-templates select='/' mode='awards'/></r>",
      '
      <fb>
        <f><who>1</who><who_name>jeff</who_name><award>10</award><when>2024-07-02T00:00:00Z</when></f>
        <f><is_human>0</is_human><who>2</who><who_name>robot</who_name><award>99</award>
          <when>2024-07-02T00:00:00Z</when></f>
      </fb>
      ',
      'today' => '2024-07-05T00:00:00Z'
    )
    names = xml.xpath('//table[@id="awards"]/tbody/tr[not(contains(@class, "sub"))]/td[2]/span/a')
    assert_equal(['@jeff'], names.map(&:text), xml)
  end

  def test_fn_payables_counts_awards_with_unknown_humanity
    xml = xslt(
      "<r><xsl:copy-of select=\"z:payables('dude')\"/></r>",
      '
      <fb>
        <f>
          <what>reconciliation</what>
          <when>2026-10-01T10:00:00Z</when>
          <since>2026-09-20T00:00:00Z</since>
          <who_name>dude</who_name>
          <awarded>0</awarded>
          <payout>0</payout>
          <balance>0</balance>
        </f>
        <f><when>2026-10-05T10:00:00Z</when><who_name>dude</who_name><award>30</award></f>
        <f><is_human>0</is_human><when>2026-10-05T10:00:00Z</when><who_name>dude</who_name><award>7</award></f>
      </fb>
      ',
      'today' => '2026-10-14T12:00:00Z'
    )
    assert_equal('30', xml.xpath('/r/td').text.strip, xml)
  end
end
