<?php


$rows = [
    'row1' => [
        'key'  => 'value',
        'key2' => 'value2',
        'key3' => 'value3',
    ],
    'row2' => [
        'key'            => 'value',
        'key2 different' => 'value2',
        'key3'           => 'value3',
    ],
    'row3' => [
        'key'  => 'value',
        'key2' => 'value2',
        'key3' => 'value3',
    ],
    'row4' => [
        'key'  => 'value',
        'key2' => 'value2',
        'key3' => 'value3',
    ],
    'row5' => [
        'key'  => 'value',
        'key2' => 'value altered',
        'key3' => 'value3',
    ],
    'row6' => [
        'key'  => 'value',
    ],
];


function compareAll($rows)
{
    // Flatten all possible values for all points in the array
    $diff = [];
    foreach ($rows as $keya => $rowa) {
        $diff[$keya] = [];
        foreach ($rows as $keyb => $rowb) {
            if ($keyb !== $keya) {
                $diff[$keya] = array_merge($diff[$keya], compareOne($rowa, $rowb));
            }
        }
    }

    return $diff;
}

function compareOne($rowa, $rowb)
{
    ksort($rowa);
    ksort($rowb);
    if ($rowa === $rowb) {
        return [];
    }
    $diff = [];
    foreach ($rowa as $key => $value) {
        if (isset($rowb[$key])) {
            if (is_array($value)) {
                $diff[$key] = compareOne($value, $rowb[$key]);
            } else {
                if ($value !== $rowb[$key]) {
                    $diff[$key] = $value;
                }
            }
        } else {
            $diff[$key] = $value;
        }
    }

    return $diff;
}

die(var_dump(compareAll($rows)));