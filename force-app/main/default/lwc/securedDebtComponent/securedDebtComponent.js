import { LightningElement } from 'lwc';

const columns = [
    { label: 'Type', fieldName: 'Type', hideDefaultActions: true }, //cellAttributes: { alignment: 'center'},
    { label: 'Source', fieldName: 'Source', hideDefaultActions: true},
    { label: 'Recommend.', fieldName: 'Recommend', hideDefaultActions: true},
    { label: 'Balance', fieldName: 'Balance', type: 'currency', cellAttributes: { alignment: 'left'}, hideDefaultActions: true },
    { label: 'Payout', fieldName: 'Payout', type: 'currency', cellAttributes: { alignment: 'left'}, hideDefaultActions: true },
    { label: 'Record', fieldName: 'Record', type: 'url', typeAttributes: { label: {fieldName: 'Record'}},hideDefaultActions: true }
];
export default class SecuredDebtComponent extends LightningElement {
    columns = columns;

    data = [
        {
            Type: 'Mortgage',
            Source: 'Transunion',
            Recommend: 'Required',
            Balance: '100000',
            Payout: '100000',
            Record: 'Debt_1002'
        },
        {
            Type: 'HELOC',
            Source: 'Transunion',
            Recommend: 'Required',
            Balance: '10000',
            Payout: '10000',
            Record: 'Debt_1002'
        }
    ]
}