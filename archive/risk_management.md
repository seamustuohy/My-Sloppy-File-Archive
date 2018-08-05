---
layout: page
title: Risk Management
description: "Risk Management Archive."
---

## Publications by date

{% assign grouped_refs = site.data.refs | group_by: "year"  | sort: "name","last" | reverse %}

{% for year in grouped_refs %}
{% assign addition = year.name | plus: 0 %}
{% capture addition %}{{addition}}{% endcapture %}
{% if year.name == addition %}

<h2> {{ year.name }}</h2>

<ul class="listing">
    {% for ref in year.items %}
    {% if ref.title %}
    {% if ref.type contains "risk_management" %}

  <li class="listing-item">
    <!--<time datetime="{{ ref.creation_date }}">{{ref.creation_date}}</time>-->
    <a href="{{ ref.local_path }}" title="{{ ref.title }}">{{ ref.title }} ({{ ref.form | split: '/' | last }})</a>
    - {{ref.organization}}

  </li>

<!-- {% if ref.description %}
{{ref.description}}
{% endif %} -->
{% endif %}
{% endif %}
{% endfor %}
</ul>
{% endif %}
{% endfor %}

{% for year in grouped_refs %}
  {% if year.name == "unknown" %}
<h2> {{ year.name }}</h2>

<ul class="listing">
    {% for ref in year.items %}
      {% if ref.title %}
        {% if ref.type contains "risk_management" %}
  <li class="listing-item">
    <!--<time datetime="{{ ref.creation_date }}">{{ref.creation_date}}</time>-->
    <a href="{{ ref.local_path }}" title="{{ ref.title }}">{{ ref.title }} ({{ ref.form | split: '/' | last }})</a> - {{ref.organization}}</li>
        {% endif %}
      {% endif %}
    {% endfor %}
  {% endif %}
{% endfor %}
