import { LightningElement } from 'lwc';

const columns = [
    { label: 'Type', fieldName: 'Type', hideDefaultActions: true }, //cellAttributes: { alignment: 'center'},
    { label: 'Source', fieldName: 'Source', hideDefaultActions: true},
    { label: 'Recommend.', fieldName: 'Recommend', hideDefaultActions: true},
    { label: 'Balance', fieldName: 'Balance', type: 'currency', cellAttributes: { alignment: 'left'}, hideDefaultActions: true },
    { label: 'Payout', fieldName: 'Payout', type: 'currency', cellAttributes: { alignment: 'left'}, hideDefaultActions: true },
    { label: 'Record', fieldName: 'Record', type: 'url', typeAttributes: { label: {fieldName: 'Record'}},hideDefaultActions: true }
];

export default class OtherLiabilitiesDebtsComponent extends LightningElement {
    columns = columns;

    data = [
        {
            Type: 'Credit Card',
            Source: 'Credit',
            Recommend: 'Example',
            Balance: '2000',
            Payout: '2000',
            Record: 'Debt_1002'
        }
    ]
}