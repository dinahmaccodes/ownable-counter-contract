// use cohort_4::aggregator::{IAggregatorDispatcher, IAggregatorDispatcherTrait};
// use cohort_4::counter::{
//     ICounterDispatcher, ICounterDispatcherTrait, ICounterSafeDispatcher,
//     ICounterSafeDispatcherTrait,
// };
// use cohort_4::killswitch::{IKillSwitchDispatcher, IKillSwitchDispatcherTrait};
// use cohort_4::ownable::{IOwnableDispatcher, IOwnableDispatcherTrait};
// use core::traits::TryInto;
// use snforge_std::{
//     ContractClassTrait, DeclareResultTrait, EventSpyAssertionsTrait, declare, spy_events,
//     start_cheat_caller_address, stop_cheat_caller_address,
// };
// use starknet::{ContractAddress, contract_address_const};

use crate::EventSpyAssertionsTrait;
use super::*;
fn deploy_aggregator_contract() -> (
    ICounterDispatcher, IKillSwitchDispatcher, IAggregatorDispatcher, IOwnableDispatcher,
) {
    //counter deployment
    let counter_countract_name: ByteArray = "Counter";
    let contract = declare(counter_countract_name)
        .expect('counter contract is not working')
        .contract_class();
    let (counter_contract_address, _) = contract
        .deploy(@ArrayTrait::new())
        .expect('counter address issue');
    let counter_dispatcher = ICounterDispatcher { contract_address: counter_contract_address };

    //killswitch deployment
    let killswitch_contract_name: ByteArray = "KillSwitch";
    let killswitch_contract = declare(killswitch_contract_name)
        .expect('killswitch contract not working')
        .contract_class();
    let (killswitch_contract_address, _) = killswitch_contract
        .deploy(@ArrayTrait::new())
        .expect('killswitch address issue');
    let killswitch_dispatcher = IKillSwitchDispatcher {
        contract_address: killswitch_contract_address,
    };

    //ownable deployment
    let ownable_contract_name: ByteArray = "Ownable";
    let ownable_contract = declare(ownable_contract_name)
        .expect('ownable contract not working')
        .contract_class();
    let (ownable_contract_address, _) = ownable_contract
        .deploy(@array![OWNER().into()])
        .expect('ownable address issue');
    let ownable = IOwnableDispatcher { contract_address: ownable_contract_address };

    //aggregator deployment
    let aggregator = declare("Aggregator").expect('aggregator contract error').contract_class();
    let (aggregator_contract_address, _) = aggregator
        .deploy(
            @array![
                counter_contract_address.into(),
                killswitch_contract_address.into(),
                ownable_contract_address.into(),
            ],
        )
        .expect('aggregator address issue');

    let aggregator_dispatcher = IAggregatorDispatcher {
        contract_address: aggregator_contract_address,
    };

    (counter_dispatcher, killswitch_dispatcher, aggregator_dispatcher, ownable)
}

//Test accounts
fn OWNER() -> ContractAddress {
    'OWNER'.try_into().unwrap()
}

fn NON_OWNER() -> ContractAddress {
    'NON_OWNER'.try_into().unwrap()
}

fn NEW_OWNER() -> ContractAddress {
    'NEW_OWNER'.try_into().unwrap()
}


#[test]
fn test_initial_count_balance_aggregator() {
    let (_, _, aggregator_dispatcher, _) = deploy_contract();
    //start prank as owner
    start_cheat_caller_address(aggregator_dispatcher.contract_address, OWNER());
    //check balance to ensure it is zero
    let count_before = aggregator_dispatcher.get_count();
    assert(count_before == 0, 'wrong intial count');
    stop_cheat_caller_address(aggregator_dispatcher.contract_address);
}


#[test]
fn test_increase_count_aggregator() {
    let (_, _, aggregator_dispatcher, _) = deploy_contract();
    //start prank as owner
    start_cheat_caller_address(aggregator_dispatcher.contract_address, OWNER());
    let balance_1 = aggregator_dispatcher.get_count();
    assert(balance_1 == 0, 'wrong starting balance');
    //increase count
    aggregator_dispatcher.increase_count(42);

    let balance_after = aggregator_dispatcher.get_count();
    //check balance to be sure increase occured
    assert(balance_after == 42, 'wrong new balance');
    stop_cheat_caller_address(aggregator_dispatcher.contract_address);
}

#[test]
fn test_increase_counter_count_aggregator() {
    let (counter_dispatcher, killswitch_dispatcher, aggregator_dispatcher, _) = deploy_contract();

    //start prank as owner
    start_cheat_caller_address(aggregator_dispatcher.contract_address, OWNER());
    let count_1 = aggregator_dispatcher.get_count();
    assert(count_1 == 0, 'invalid count 1');

    //check if killswitch is off
    let status_before = killswitch_dispatcher.get_status();
    assert(!status_before, 'incorrect killswitch status');
    //turn on the switch
    aggregator_dispatcher.activate_switch();
    let status_after = killswitch_dispatcher.get_status();
    assert(status_after, 'failed to activate');
    //increase the counter count
    aggregator_dispatcher.increase_counter_count(42);

    //check if the count increased
    let count_2 = counter_dispatcher.get_count();
    assert(count_2 == 42, 'invalid count_2');
}


#[test]
fn test_decrease_count_by_one_aggregator() {
    let (_, _, aggregator_dispatcher, _) = deploy_aggregator_contract();

    start_cheat_caller_address(aggregator_dispatcher.contract_address, OWNER());
    let count_before = aggregator_dispatcher.get_count();
    assert(count_before == 0, 'intial count is not zero');

    aggregator_dispatcher.increase_count(58);
    aggregator_dispatcher.decrease_count_by_one();

    let count_after = aggregator_dispatcher.get_count();
    stop_cheat_caller_address(aggregator_dispatcher.contract_address);
    assert(count_after == 57, 'count is incorrect');
}

#[test]
fn test_activate_switch_aggregator() {
    let (_, killswitch_dispatcher, aggregator_dispatcher, _) = deploy_contract();
    // check kill status_
    let status = killswitch_dispatcher.get_status();
    assert(!status, 'switch status failed');

    // Start prank as owner
    start_cheat_caller_address(aggregator_dispatcher.contract_address, OWNER());
    // Activate the switch
    aggregator_dispatcher.activate_switch();
    stop_cheat_caller_address(aggregator_dispatcher.contract_address);
    //check status once more
    let status_after = killswitch_dispatcher.get_status();
    assert(status_after, 'switch status not active');
}

#[test]
#[should_panic(expect: 'Amount cannot be 0')]
fn test_increase_count_aggregator_by_zero() {
    let (_, _, aggregator_dispatcher, _) = deploy_contract();

    start_cheat_caller_address(aggregator_dispatcher.contract_address, OWNER());

    let count_before = aggregator_dispatcher.get_count();
    assert(count_before == 0, 'wrong intial count');
    aggregator_dispatcher.increase_count(0);
    stop_cheat_caller_address(aggregator_dispatcher.contract_address);
}


#[test]
#[should_panic(expect: 'Caller is not owner')]
fn test_should_panic_initial_count_balance_aggregator() {
    let (_, _, aggregator_dispatcher, _) = deploy_contract();
    //start prank as owner
    start_cheat_caller_address(aggregator_dispatcher.contract_address, NON_OWNER());
    //check balance to ensure it is zero
    let count_before = aggregator_dispatcher.get_count();
    assert(count_before == 0, 'wrong intial count');
    stop_cheat_caller_address(aggregator_dispatcher.contract_address);
}

#[test]
#[should_panic(expect: 'Caller is not owner')]
fn test_should_panic_increase_count_aggregator() {
    let (_, _, aggregator_dispatcher, _) = deploy_contract();
    //start prank as owner
    start_cheat_caller_address(aggregator_dispatcher.contract_address, NON_OWNER());
    let balance_1 = aggregator_dispatcher.get_count();
    assert(balance_1 == 0, 'wrong starting balance');
    //increase count
    aggregator_dispatcher.increase_count(42);

    let balance_after = aggregator_dispatcher.get_count();
    //check balance to be sure increase occured
    assert(balance_after == 42, 'wrong new balance');
    stop_cheat_caller_address(aggregator_dispatcher.contract_address);
}


#[test]
#[should_panic(expect: 'Caller is not owner')]
fn test_should_panic_decrease_count_by_one_aggregator() {
    let (_, _, aggregator_dispatcher, _) = deploy_aggregator_contract();

    start_cheat_caller_address(aggregator_dispatcher.contract_address, NON_OWNER());
    let count_before = aggregator_dispatcher.get_count();
    assert(count_before == 0, 'intial count is not zero');

    aggregator_dispatcher.increase_count(58);
    aggregator_dispatcher.decrease_count_by_one();

    let count_after = aggregator_dispatcher.get_count();
    stop_cheat_caller_address(aggregator_dispatcher.contract_address);
    assert(count_after == 57, 'count is incorrect');
}

#[test]
#[should_panic(expect: 'Caller is not owner')]
fn test_should_panic_activate_switch_aggregator() {
    let (_, killswitch_dispatcher, aggregator_dispatcher, _) = deploy_contract();
    // check kill status_
    let status = killswitch_dispatcher.get_status();
    assert(!status, 'switch status failed');

    // Start prank as owner
    start_cheat_caller_address(aggregator_dispatcher.contract_address, NON_OWNER());
    // Activate the switch
    aggregator_dispatcher.activate_switch();
    stop_cheat_caller_address(aggregator_dispatcher.contract_address);
    //check status once more
    let status_after = killswitch_dispatcher.get_status();
    assert(status_after, 'switch status not active');
}
// Tests to check for events!

#[test]
fn test_should_emit_increase_count_aggregator() {
    let (_, _, aggregator_dispatcher, _) = deploy_contract();

    let mut spy = spy_events();

    //start prank as owner
    start_cheat_caller_address(aggregator_dispatcher.contract_address, OWNER());

    let balance_1 = aggregator_dispatcher.get_count();
    assert(balance_1 == 0, 'wrong starting balance');

    //increase count
    aggregator_dispatcher.increase_count(42);

    let balance_after = aggregator_dispatcher.get_count();
    //check balance to be sure increase occured
    assert(balance_after == 42, 'wrong new balance');
    stop_cheat_caller_address(aggregator_dispatcher.contract_address);

    let expected_event = Event::CountIncreased(
        CountIncreased { new_count: balance_after, caller: OWNER() },
    );

    // Assert the event was emitted
    spy.assert_emitted(@array![(aggregator_dispatcher.contract_address, expected_event)]);
}

#[test]
fn test_should_emit_increase_counter_count_aggregator() {
    let (counter_dispatcher, killswitch_dispatcher, aggregator_dispatcher, _) = deploy_contract();

    let mut spy = spy_events();

    //start prank as owner
    start_cheat_caller_address(aggregator_dispatcher.contract_address, OWNER());
    let count_1 = aggregator_dispatcher.get_count();
    assert(count_1 == 0, 'invalid count 1');

    //check if killswitch is off
    let status_before = killswitch_dispatcher.get_status();
    assert(!status_before, 'incorrect killswitch status');
    //turn on the switch
    aggregator_dispatcher.activate_switch();
    let status_after = killswitch_dispatcher.get_status();
    assert(status_after, 'failed to activate');
    //increase the counter count
    aggregator_dispatcher.increase_counter_count(42);

    //check if the count increased
    let count_2 = counter_dispatcher.get_count();
    assert(count_2 == 42, 'invalid count_2');
    stop_cheat_caller_address(aggregator_dispatcher.contract_address);

    let expected_event = Event::CounterCountIncreased(
        CounterCountIncreased { new_counter: count_2, caller: OWNER() },
    );

    //Check if the event was emmitted
    spy.assert_emitted(@array![(aggregator_dispatcher.contract_address, expected_event)]);
}

#[test]
fn test_should_emit_decrease_count_by_one_aggregator() {
    let (_, _, aggregator_dispatcher, _) = deploy_aggregator_contract();

    let mut spy = spy_events();
    //start prank as owner
    start_cheat_caller_address(aggregator_dispatcher.contract_address, OWNER());
    let count_before = aggregator_dispatcher.get_count();
    assert(count_before == 0, 'intial count is not zero');
    //increase count to have value > 0 to decrease from
    aggregator_dispatcher.increase_count(58);
    aggregator_dispatcher.decrease_count_by_one();
    //check new count value
    let count_after = aggregator_dispatcher.get_count();
    stop_cheat_caller_address(aggregator_dispatcher.contract_address);
    //assert that you have the right count value
    assert(count_after == 57, 'count is incorrect');
    stop_cheat_caller_address(aggregator_dispatcher.contract_address);

    let expected_event = Event::CountDecreasedByOne(
        CountDecreasedByOne { new_count: count_after, caller: OWNER() },
    );
    //check that event was emitted
    spy.assert_emitted(@array![(aggregator_dispatcher.contract_address, expected_event)]);
}

#[test]
fn test_should_emit_activate_switch_aggregator() {
    let (_, killswitch_dispatcher, aggregator_dispatcher, _) = deploy_contract();

    let mut spy = spy_events();

    // check kill status
    let status = killswitch_dispatcher.get_status();
    assert(!status, 'switch status failed');

    // Start prank as owner
    start_cheat_caller_address(aggregator_dispatcher.contract_address, OWNER());
    // Activate the switch
    aggregator_dispatcher.activate_switch();
    stop_cheat_caller_address(aggregator_dispatcher.contract_address);
    //check status once more
    let status_after = killswitch_dispatcher.get_status();
    assert(status_after, 'switch status not active');

    let expected_event = Event::SwitchStatus(SwitchStatus { status: status_after, caller: OWNER()});

    //check that event was emitted
    spy.assert_emitted(@array![(aggregator_dispatcher.contract_address, expected_event)]);

}

