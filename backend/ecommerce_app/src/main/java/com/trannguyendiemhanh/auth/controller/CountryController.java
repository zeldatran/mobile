package com.trannguyendiemhanh.auth.controller;

import com.trannguyendiemhanh.auth.entity.Country;
import com.trannguyendiemhanh.auth.service.CountryService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/countries")
public class CountryController extends CrudController<Country, Integer> {
    public CountryController(CountryService service) {
        super(service);
    }
}
