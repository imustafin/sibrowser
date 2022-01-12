import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const parentComponent = this.element.closest('[data-controller=packages_paginated--component]');

    if (!parentComponent) {
      setTimeout(100, this.connect);
      return;
    }

    const parentController = this
      .application
      .getControllerForElementAndIdentifier(
        parentComponent,
        'packages_paginated--component'
      );

    if (!parentController) {
      setTimeout(100, this.connect);
      return;
    }

    parentController.registerBeforeFirst(this.element);
  }
}
