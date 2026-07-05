import Component from "@glimmer/component";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import {
  nextTopicUrl,
  previousTopicUrl,
  setTopicId,
} from "discourse/lib/topic-list-tracker";
import DiscourseURL from "discourse/lib/url";
import { inject as service } from "@ember/service";

// Topic URLs look like [/basePath]/t/<slug>/<id>[/<post>]
function topicIdFromUrl(url) {
  const match = url?.match(/\/t\/[^/]+\/(\d+)/);
  return match ? parseInt(match[1], 10) : null;
}

export default class TopicNextButton extends Component {
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

  get shouldShow() {
    return this.showButton && this.showInCategory;
  }

  get showInCategory() {
    return (
      settings.topic_next_categories === "" ||
      settings.topic_next_categories
        .split("|")
        .includes(`${this.args.topic?.category_id}`)
    );
  }

  get goFirst() {
    return settings.topic_next_always_go_to_first_post;
  }

  // nextTopicUrl() is a stateful iterator step on the shared
  // topic-list-tracker pointer, and when the current topic is missing from
  // the tracked list it falls back to the list's first topic. Walking one
  // step forward and back proves the current topic is really in the list,
  // and setTopicId() leaves the shared pointer where core expects it.
  async validatedNextUrl() {
    const currentTopicId = this.args.topic?.id;
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
    if (this.goFirst) {
      const match = url.match(/^(.*?\/t\/[^/]+\/\d+)/);
      target = match ? match[1] : url;
    }
    DiscourseURL.routeTo(target);
  }
}
