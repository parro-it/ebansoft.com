

{{ useLayout("../layouts/home.njk") }}
{{ title("EbanSoft blog | drafts") }}
{{ subtitle("Thoughts on Javascript and C development.") }}

__Latest articles__

| Title  | Date | ~  |
|--------|------|----|{% for path, post in registry.entries %}{% if ('posts' in post.categories) %}
|{{post.title}}|{{post.publishedFormatted}}|Edit|{% endif %}{% endfor %}

{% for path, post in registry.entries %}
{% if ('posts' in post.categories) %}

## [{{ post.title }}]({{ post.url }})
<time datetime="{{ post.published }}">{{ post.publishedFormatted }}</time>

![{{ post.headingCaption }}]({{ post.headingFigure }})

{{ post.subtitle }}

{% endif %}
{% endfor %}