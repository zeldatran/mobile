package com.trannguyendiemhanh.auth.repository;

import com.trannguyendiemhanh.auth.entity.Country;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface CountryRepository extends JpaRepository<Country, Integer> {}
