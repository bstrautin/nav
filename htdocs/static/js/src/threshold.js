require(['libs/jquery', 'libs/jquery-ui-1.8.21.custom.min', 'libs/spin.min'], function () {
    /* The global variable metric is set in the base template of the threshold page */

    var $inputElement = $('#id_target'),
        $rawButton = $('#id_raw'),
        $refreshButton = $('#refresh-graph'),
        $dataElement = $inputElement.parents('.dataelement'),
        metric = $dataElement.attr('data-metric'),
        $metricGraph = $('.metricGraph'),
        spinner = new Spinner();

    $(function () {
        $inputElement.autocomplete(
            {
                'delay': 300,
                'minLength': 3,
                'source': $dataElement.attr('data-url'),
                'select': handleSelect
            }
        );

        if (metric) {
            displayMetricInfo(metric);
        }

        /* Redraw graph when raw checkbox is clicked */
        $rawButton.on('click', function () {
            displayMetricInfo($inputElement.val());
        });

        /* Redraw graph when refreshbutton is clicked */
        $refreshButton.on('click', function () {
            displayMetricInfo($inputElement.val());
        });

        /* Closes dialog for deleting rules when button inside dialog is clicked */
        $('#thresholdrules').on('click', '.f-dropdown .close-button', function () {
            var $element = $(this),
                $parent = $element.parents('.f-dropdown').first();

            if ($parent.hasClass('open')) {
                $(document).foundation('dropdown', 'close', $parent);
            }
        });

    });

    function handleSelect(event, ui) {
        if (ui.item.expandable) {
            $inputElement.autocomplete('search', ui.item.value + '.');
        } else {
            displayMetricInfo(ui.item.value);
        }
    }

    function displayMetricInfo(metric) {
        startSpinner();
        var image = new Image();
        var url = $dataElement.attr('data-renderurl') + '?metric=' + metric;
        if ($rawButton.prop('checked')) {
            url += '&raw=true';
        }
        image.src = url;
        image.onload = function () {
            stopSpinner();
            $(image).appendTo($metricGraph);
        };
        image.onerror = function () {
            stopSpinner();
            $metricGraph.append('<span class="alert-box alert">Error loading graph</span>');
        };
    }

    function startSpinner() {
        $metricGraph.empty();
        $metricGraph.addClass('spinContainer');
        spinner.spin($metricGraph.get(0));  // Remember that spin does not accept jquery objects
    }

    function stopSpinner() {
        spinner.stop();
        $metricGraph.removeClass('spinContainer');
    }

});
