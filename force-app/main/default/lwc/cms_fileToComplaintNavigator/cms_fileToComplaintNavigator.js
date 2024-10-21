import { LightningElement, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { CloseActionScreenEvent } from "lightning/actions";
export default class Cms_leadToComplaintNavigator extends NavigationMixin(
  LightningElement
) {
  @api recordId;
  _recordId;

  connectedCallback() {
    console.log("123213", this.recordId);
    /**/
    const recordId = this.recordId;
    console.log("Record Id:", recordId);
    this.closeAction();
  }
  closeAction() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }

  set recordId(recordId) {
    if (recordId !== this._recordId) {
      this._recordId = recordId;
      console.log("this._recordId1", this._recordId);
      this[NavigationMixin.Navigate]({
        type: "standard__component",
        attributes: {
          componentName: "c__CMC_UrlAddressible"
        },
        state: {
          // Pass any parameters to the Aura component here
          file__recordId: this._recordId // Replace with your parameter value
        }
      });
      this.closeAction();
    }
  }
  get recordId() {
    console.log("this._recordId2", this._recordId);
    return this._recordId;
  }
}