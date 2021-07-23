

clear people
people = struct;
people.names = {...
    'chris', 'greg', 'tim', 'et', 'stan', 'wenbo', ... % Faculty
    'ari', 'nour', 'sarah', 'fredi', 'sachin', 'sofia', 'sam', ... % Summer Fellows
    };
people.projects = {};
save('people.mat', 'people')