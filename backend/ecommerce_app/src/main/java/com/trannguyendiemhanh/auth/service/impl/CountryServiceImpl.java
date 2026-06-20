package com.trannguyendiemhanh.auth.service.impl;

import com.trannguyendiemhanh.auth.entity.Country;
import com.trannguyendiemhanh.auth.repository.CountryRepository;
import com.trannguyendiemhanh.auth.service.CountryService;
import org.springframework.stereotype.Service;

@Service
public class CountryServiceImpl extends JpaCrudServiceImpl<Country, Integer> implements CountryService {
    public CountryServiceImpl(CountryRepository repository) {
        super(repository);
    }
}
