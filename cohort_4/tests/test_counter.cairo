use crate::deploy_contract;
use super::*;


#[test]
fn test_initial_count_balance() {
    let (counter_dispatcher, _, _, _) = deploy_contract();
    let count = counter_dispatcher.get_count();
    assert(count == 0, 'Wrong intial count value');
}


#[test]
fn test_increase_count() {
    let (counter_dispatcher, _, _, _) = deploy_contract();

    let balance_before = counter_dispatcher.get_count();
    assert(balance_before == 0, 'Invalid balance');

    counter_dispatcher.increase_count(42);

    let balance_after = counter_dispatcher.get_count();
    assert(balance_after == 42, 'Invalid balance');
}


#[test]
#[feature("safe_dispatcher")]
fn test_cannot_increase_balance_with_zero_value() {
    let (counter_dispatcher, _, _, _) = deploy_contract();

    let balance_before = counter_dispatcher.get_count();
    assert(balance_before == 0, 'Invalid balance');

    let safe_dispatcher = ICounterSafeDispatcher {
        contract_address: counter_dispatcher.contract_address,
    };

    match safe_dispatcher.increase_count(0) {
        Result::Ok(_) => core::panic_with_felt252('Should have panicked'),
        Result::Err(panic_data) => {
            assert(*panic_data.at(0) == 'Amount cannot be 0', *panic_data.at(0));
        },
    };
}
//Test for emit events


