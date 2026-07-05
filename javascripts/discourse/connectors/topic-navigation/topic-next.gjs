import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import {
  nextTopicUrl,
  previousTopicUrl,
  setTopicId,
} from "discourse/lib/topic-list-tracker";
import DiscourseURL from "discourse/lib/url";

// Topic URLs look like [/basePath]/t/<slug>/<id>[/<post>]
function topicIdFromUrl(url) {
  const match = url?.match(/\/t\/[^/]+\/(\d+)/);
  return match ? parseInt(match[1], 10) : null;
}

export default class TopicNext extends Component {
  @service site;
  @tracked showButton = false;

  constructor(owner, args) {
    super(owner, args);
    this.validatedNextUrl().then((url) => {
      if (this.isDestroying || this.isDestroyed) {
        return;
      }
      this.showButton = !!url;
    });
  }

  get topic() {
    return this.args.outletArgs?.topic;
  }

  get shouldShow() {
    return this.showButton && this.showInCategory;
  }

  get showInCategory() {
    return (
      settings.topic_next_categories === "" ||
      settings.topic_next_categories
        .split("|")
        .includes(`${this.topic?.category_id}`)
    );
  }

  get label() {
    return this.site.desktopView ? themePrefix("topic_next_label") : null;
  }

  // nextTopicUrl() is a stateful iterator step on the shared
  // topic-list-tracker pointer, and when the current topic is missing from
  // the tracked list it falls back to the list's first topic. Walking one
  // step forward and back proves the current topic is really in the list,
  // and setTopicId() leaves the shared pointer where core expects it.
  async validatedNextUrl() {
    const currentTopicId = this.topic?.id;
    if (!currentTopicId) {
      return null;
    }

    try {
      const url = await nextTopicUrl();
      if (!url || topicIdFromUrl(url) === currentTopicId) {
        return null;
      }
      const prevUrl = await previousTopicUrl();
      if (topicIdFromUrl(prevUrl) !== currentTopicId) {
        return null;
      }
      return url;
    } finally {
      setTopicId(currentTopicId);
    }
  }

  @action
  async goToNextTopic() {
    const url = await this.validatedNextUrl();
    if (!url) {
      this.showButton = false;
      return;
    }

    let target = url;
    if (settings.topic_next_always_go_to_first_post) {
      const match = url.match(/^(.*?\/t\/[^/]+\/\d+)/);
      target = match ? match[1] : url;
    }
    DiscourseURL.routeTo(target);
  }

  <template>
    {{#if this.shouldShow}}
      <span class="topic-next">
        <DButton
          class="topic-next-button"
          @action={{this.goToNextTopic}}
          @icon="chevron-right"
          @label={{this.label}}
        />
      </span>
    {{/if}}
  </template>
}
